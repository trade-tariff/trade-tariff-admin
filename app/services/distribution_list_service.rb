require "aws-sdk-cognitoidentityprovider"

# Manages email distribution lists. Each list is a Cognito group, in the identity
# user pool, whose name starts with "dl-".
#
# Changes are made directly in Cognito, so they take effect immediately. Each
# change writes a DistributionListAuditEvent that identifies the recipient by
# Cognito username (sub).
#
# Subscribing and unsubscribing hold a per-user lock (a Postgres advisory lock
# keyed by Cognito username), so an unsubscribe cannot delete a user while
# another admin request is subscribing them to a different list. Subscribing
# also holds a per-email lock (keyed by a digest of the normalised email) from
# before the user lookup, so only one request can find or create the user for
# an email. The request that creates a user is then the only one that can
# subscribe it, and so the one that cleans it up if the subscription fails.
# The email lock is always taken before the user lock. Identity also
# writes group memberships and does not take this lock. That race needs a user
# to sign in at the same moment as their last list is removed, and is accepted.
#
# Recipient emails are read from Cognito for display only. This service must
# never write them to the database, the cache, the logs or an exception message.
class DistributionListService
  PREFIX = "dl-".freeze
  GROUP_NAME_FORMAT = /\Adl-[a-z0-9][a-z0-9-]{0,120}\z/
  # Role/access groups. Distribution lists must never touch these.
  PROTECTED_GROUPS = %w[admin myott portal].freeze
  LOCK_TIMEOUT = 10 # seconds
  LOCK_POLL_INTERVAL = 0.1 # seconds

  # Errors a Cognito call can raise. A NetworkingError (a connection failure or
  # read timeout once the SDK's retries are used up) does not mean the request
  # failed: it may still have reached Cognito, so state-changing calls check
  # the outcome before treating it as a failure.
  CLIENT_ERRORS = [
    Aws::CognitoIdentityProvider::Errors::ServiceError,
    Seahorse::Client::NetworkingError,
  ].freeze

  Group = Data.define(:name, :description)
  Member = Data.define(:username, :email, :status, :enabled)

  class Error < StandardError; end
  class InvalidGroup < Error; end
  class NotFound < Error; end
  # Another request is changing the same recipient. Safe to retry.
  class Busy < Error; end
  # Group memberships changed after the confirmation page was shown. The
  # operator must confirm again before the Cognito account can be deleted.
  class ConfirmationRequired < Error; end

  # The user was removed from the list, but the follow-up check or deletion of
  # their Cognito user failed. The user may still hold personal information.
  class DeletionFailed < Error
    attr_reader :username

    def initialize(username, cause_name)
      @username = username
      super("Recipient #{username} was unsubscribed but not deleted (#{cause_name})")
    end
  end

  # A new Cognito user was created for a subscription that then failed, and the
  # follow-up deletion of that user also failed. The user is in no group, so
  # nothing else will clean it up.
  class CleanupFailed < Error
    attr_reader :username

    def initialize(username, cause_name)
      @username = username
      super("Recipient #{username} was created but not subscribed, and not deleted (#{cause_name})")
    end
  end

  def self.valid_group_name?(name)
    name = name.to_s
    GROUP_NAME_FORMAT.match?(name) && PROTECTED_GROUPS.exclude?(name)
  end

  def initialize(actor:, client: nil, user_pool_id: TradeTariffAdmin.cognito_user_pool_id, lock_timeout: LOCK_TIMEOUT)
    @client = client || Aws::CognitoIdentityProvider::Client.new(region: TradeTariffAdmin.cognito_region)
    @user_pool_id = user_pool_id
    @actor = actor
    @lock_timeout = lock_timeout
  end

  def groups
    paginate(:list_groups, :groups)
      .select { |group| self.class.valid_group_name?(group.group_name) }
      .map { |group| Group.new(name: group.group_name, description: group.description) }
      .sort_by(&:name)
  end

  def find_group(name)
    guard!(name)
    groups.find { |group| group.name == name } || raise(NotFound, "Distribution list not found")
  end

  def members(group_name)
    guard!(group_name)

    paginate(:list_users_in_group, :users, group_name:)
      .map { |user| to_member(user) }
      .sort_by { |member| member.email.to_s }
  rescue Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException
    raise NotFound, "Distribution list not found"
  end

  def find_member(group_name, username)
    members(group_name).find { |member| member.username == username }
  end

  # Returns :created_and_added, :added or :already_member.
  def add(group_name, email)
    guard!(group_name)
    email = normalise(email)

    # Serialises lookup, creation and the add for this email, so another
    # subscription cannot find a user this request created and take over
    # (or block) its subscription and cleanup.
    with_email_lock(email) { add_locked(group_name, email) }
  rescue Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException
    raise NotFound, "Distribution list not found"
  rescue *CLIENT_ERRORS => e
    raise Error, "Cognito could not add the recipient (#{e.class.name.demodulize})"
  end

  # True when the user is in no Cognito group other than group_name, so
  # removing them from it would delete their Cognito user.
  def last_group?(group_name, username)
    guard!(group_name)

    (user_group_names(username) - [group_name]).empty?
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    raise NotFound, "Recipient not found"
  end

  # Removes the user from the group. If that was the last group the user was
  # in (including admin, myott and portal), the Cognito user is deleted, which
  # removes their email and every other attribute held in Cognito.
  #
  # Returns :removed or :removed_and_deleted.
  def remove(group_name, username, account_deletion_acknowledged: false)
    guard!(group_name)

    # Recheck the remaining groups under the lock before changing membership.
    # If account deletion is newly required, return to confirmation without
    # removing the recipient.
    with_user_lock(username) do
      # Only a recipient of this list can be unsubscribed (and so deleted).
      raise NotFound, "Recipient not found" unless find_member(group_name, username)

      deletes_account = (user_group_names(username) - [group_name]).empty?
      if deletes_account && !account_deletion_acknowledged
        raise ConfirmationRequired, "Cognito account deletion must be confirmed"
      end

      remove_from_group(group_name, username)
      audit("recipient_removed", group_name, username)

      deletes_account ? delete_if_in_no_groups(group_name, username) : :removed
    end
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException,
         Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException
    raise NotFound, "Recipient or distribution list not found"
  rescue *CLIENT_ERRORS => e
    raise Error, "Cognito could not remove the recipient (#{e.class.name.demodulize})"
  end

private

  attr_reader :client, :user_pool_id, :actor, :lock_timeout

  def add_locked(group_name, email)
    attempts = 0

    begin
      attempts += 1
      username, created = ensure_user(email, group_name)

      # Holding the lock stops a concurrent unsubscribe from deleting this user
      # between the membership check and the add.
      with_user_lock(username) do
        next :already_member if !created && find_member(group_name, username)

        add_to_group(group_name, username, created:)
        audit("recipient_added", group_name, username)

        created ? :created_and_added : :added
      end
    rescue Busy
      # A user created by this request is new, so no unsubscribe can be
      # holding its lock. If one is, the user cannot be safely deleted here:
      # report it so the operator can have it checked.
      raise CleanupFailed.new(username, "Busy") if created

      raise
    rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
      # An unsubscribe deleted the user after ensure_user found them. Creating
      # the user again gives them a new username, so take the lock again.
      retry if attempts < 2
      raise NotFound, "Recipient not found"
    end
  end

  def with_email_lock(email, &)
    with_advisory_lock("distribution_list_email:#{user_pool_id}:#{Digest::SHA256.hexdigest(email)}", &)
  end

  def with_user_lock(username, &)
    with_advisory_lock("distribution_list_user:#{user_pool_id}:#{username}", &)
  end

  # Session-level advisory lock, so audit events written inside the block are
  # committed even if a later Cognito call fails. The lock is released when the
  # block ends, or by Postgres if the connection is lost.
  def with_advisory_lock(key)
    connection = DistributionListAuditEvent.connection
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + lock_timeout

    until advisory_lock_query(connection, "pg_try_advisory_lock", key)
      raise Busy, "Another change to this recipient is in progress" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      sleep LOCK_POLL_INTERVAL
    end

    begin
      yield
    ensure
      advisory_lock_query(connection, "pg_advisory_unlock", key)
    end
  end

  def advisory_lock_query(connection, function, key)
    DistributionListAuditEvent.uncached do
      connection.select_value(
        ActiveRecord::Base.sanitize_sql_array(["SELECT #{function}(hashtextextended(?, 0))", key]),
      )
    end
  end

  def guard!(name)
    raise InvalidGroup, "Not a distribution list" unless self.class.valid_group_name?(name)
  end

  def normalise(email)
    email.to_s.strip.downcase
  end

  # Returns [cognito_username, created?]. The pool uses email as a username
  # attribute, so AdminGetUser accepts the email and returns the internal
  # username (the sub).
  def ensure_user(email, group_name)
    [client.admin_get_user(user_pool_id:, username: email).username, false]
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    begin
      username = create_user(email)
      audit("user_created", group_name, username)
      [username, true]
    rescue Aws::CognitoIdentityProvider::Errors::UsernameExistsException
      [client.admin_get_user(user_pool_id:, username: email).username, false]
    end
  end

  def create_user(email)
    client.admin_create_user(
      user_pool_id:,
      username: email,
      message_action: "SUPPRESS",
      user_attributes: [
        { name: "email", value: email },
        # Required: identity's RemoveUnverifiedUsers sweep deletes users
        # whose email is not verified.
        { name: "email_verified", value: "true" },
      ],
    ).user.username
  rescue Seahorse::Client::NetworkingError => e
    # The create may have reached Cognito. The user did not exist just before,
    # so if it exists now, treat it as created here so a failed add cleans it up.
    existing_username(email) || raise(e)
  end

  # If this request created the user and the add fails, the user would stay in
  # Cognito in no group: not on any list page, and skipped by identity's
  # unverified-user sweep because the email is verified. Delete it so a failed
  # subscription leaves no personal data behind.
  def add_to_group(group_name, username, created:)
    client.admin_add_user_to_group(user_pool_id:, username:, group_name:)
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    raise
  rescue *CLIENT_ERRORS => e
    # The add may have reached Cognito (for example, a read timeout). If the
    # user is in the group, the subscription worked.
    groups = current_group_names(username)
    return if groups&.include?(group_name)

    discard_created_user(group_name, username, groups) if created
    raise e
  end

  # groups is the user's current groups, or nil if they could not be read.
  def discard_created_user(group_name, username, groups)
    # Another writer (for example identity) may have added the user to a group
    # since it was created. Then it is no longer orphaned, so keep it.
    return if (groups || user_group_names(username)).any?

    audit("user_deleted", group_name, username) if delete_user(username)
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    nil
  rescue Error, *CLIENT_ERRORS => e
    raise CleanupFailed.new(username, e.class.name.demodulize)
  end

  def remove_from_group(group_name, username)
    client.admin_remove_user_from_group(user_pool_id:, username:, group_name:)
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException,
         Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException
    raise
  rescue *CLIENT_ERRORS => e
    # The removal may have reached Cognito (for example, a read timeout). If
    # the user has left the group, carry on, so that a user left in no group
    # is still deleted.
    groups = current_group_names(username)
    raise e unless groups && groups.exclude?(group_name)
  end

  def delete_if_in_no_groups(group_name, username)
    return :removed if user_group_names(username).any?

    audit("user_deleted", group_name, username) if delete_user(username)
    :removed_and_deleted
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    :removed_and_deleted
  rescue Error, *CLIENT_ERRORS => e
    raise DeletionFailed.new(username, e.class.name.demodulize)
  end

  # Returns true if this call deleted the user, false if it was already gone.
  def delete_user(username)
    client.admin_delete_user(user_pool_id:, username:)
    true
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    false
  rescue Seahorse::Client::NetworkingError => e
    # The delete may have reached Cognito. Only report a failure if the user
    # is still there.
    raise e if existing_username(username)

    true
  end

  # The Cognito username for a username or email, or nil if there is no user.
  def existing_username(username)
    client.admin_get_user(user_pool_id:, username:).username
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    nil
  end

  def user_group_names(username)
    paginate(:admin_list_groups_for_user, :groups, username:).map(&:group_name)
  end

  # The user's groups, [] if the user no longer exists, or nil if the groups
  # could not be read.
  def current_group_names(username)
    user_group_names(username)
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    []
  rescue Error
    nil
  end

  def paginate(method, collection, **args)
    results = []
    next_token = nil

    loop do
      response = client.public_send(method, { user_pool_id:, next_token:, **args }.compact)
      results.concat(response.public_send(collection))
      next_token = response.next_token
      break if next_token.blank?
    end

    results
  rescue Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException,
         Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    raise
  rescue *CLIENT_ERRORS => e
    raise Error, "Cognito request failed (#{e.class.name.demodulize})"
  end

  def to_member(user)
    attributes = Array(user.attributes).to_h { |attribute| [attribute.name, attribute.value] }

    Member.new(
      username: user.username,
      email: attributes["email"],
      status: user.user_status,
      enabled: user.enabled,
    )
  end

  # Records who did what to which list, and when. The recipient is identified
  # by the Cognito username (sub), never by email.
  def audit(action, group_name, username)
    event = DistributionListAuditEvent.create!(
      actor_uid: actor.uid,
      actor_name: actor.name,
      action:,
      group_name:,
      recipient_username: username,
    )

    Rails.logger.info(
      {
        event: "distribution_list.#{action}",
        actor_uid: event.actor_uid,
        group: group_name,
        recipient_username: username,
        at: event.created_at.iso8601,
      }.to_json,
    )
  end
end
