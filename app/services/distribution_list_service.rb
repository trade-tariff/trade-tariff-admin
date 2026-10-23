require "aws-sdk-cognitoidentityprovider"

# Manages email distribution lists. Each list is a Cognito group, in the identity
# user pool, whose name starts with "dl-".
#
# Changes are made directly in Cognito, so they take effect immediately. Each
# change writes a DistributionListAuditEvent that identifies the recipient by
# Cognito username (sub).
#
# Recipient emails are read from Cognito for display only. This service must
# never write them to the database, the cache, the logs or an exception message.
class DistributionListService
  PREFIX = "dl-".freeze
  GROUP_NAME_FORMAT = /\Adl-[a-z0-9][a-z0-9-]{0,120}\z/
  # Role/access groups. Distribution lists must never touch these.
  PROTECTED_GROUPS = %w[admin myott portal].freeze

  Group = Data.define(:name, :description)
  Member = Data.define(:username, :email, :status, :enabled)

  class Error < StandardError; end
  class InvalidGroup < Error; end
  class NotFound < Error; end

  # The user was removed from the list, but the follow-up check or deletion of
  # their Cognito user failed. The user may still hold personal information.
  class DeletionFailed < Error
    attr_reader :username

    def initialize(username, cause_name)
      @username = username
      super("Recipient #{username} was unsubscribed but not deleted (#{cause_name})")
    end
  end

  def self.valid_group_name?(name)
    name = name.to_s
    GROUP_NAME_FORMAT.match?(name) && PROTECTED_GROUPS.exclude?(name)
  end

  def initialize(actor:, client: nil, user_pool_id: TradeTariffAdmin.cognito_user_pool_id)
    @client = client || Aws::CognitoIdentityProvider::Client.new(region: TradeTariffAdmin.cognito_region)
    @user_pool_id = user_pool_id
    @actor = actor
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

    username, created = ensure_user(normalise(email), group_name)

    if !created && find_member(group_name, username)
      return :already_member
    end

    client.admin_add_user_to_group(user_pool_id:, username:, group_name:)
    audit("recipient_added", group_name, username)

    created ? :created_and_added : :added
  rescue Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException
    raise NotFound, "Distribution list not found"
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise Error, "Cognito refused to add the recipient (#{e.class.name.demodulize})"
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
  def remove(group_name, username)
    guard!(group_name)

    raise NotFound, "Recipient not found" unless find_member(group_name, username)

    client.admin_remove_user_from_group(user_pool_id:, username:, group_name:)
    audit("recipient_removed", group_name, username)

    delete_if_in_no_groups(group_name, username)
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException,
         Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException
    raise NotFound, "Recipient or distribution list not found"
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise Error, "Cognito refused to remove the recipient (#{e.class.name.demodulize})"
  end

private

  attr_reader :client, :user_pool_id, :actor

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
      response = client.admin_create_user(
        user_pool_id:,
        username: email,
        message_action: "SUPPRESS",
        user_attributes: [
          { name: "email", value: email },
          # Required: identity's RemoveUnverifiedUsers sweep deletes users
          # whose email is not verified.
          { name: "email_verified", value: "true" },
        ],
      )
      audit("user_created", group_name, response.user.username)
      [response.user.username, true]
    rescue Aws::CognitoIdentityProvider::Errors::UsernameExistsException
      [client.admin_get_user(user_pool_id:, username: email).username, false]
    end
  end

  def delete_if_in_no_groups(group_name, username)
    return :removed if user_group_names(username).any?

    client.admin_delete_user(user_pool_id:, username:)
    audit("user_deleted", group_name, username)
    :removed_and_deleted
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    :removed_and_deleted
  rescue Error, Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise DeletionFailed.new(username, e.class.name.demodulize)
  end

  def user_group_names(username)
    paginate(:admin_list_groups_for_user, :groups, username:).map(&:group_name)
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
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
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
