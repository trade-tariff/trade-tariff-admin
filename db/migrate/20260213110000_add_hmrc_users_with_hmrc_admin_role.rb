class AddHmrcUsersWithHmrcAdminRole < ActiveRecord::Migration[8.0]
  HMRC_USER_EMAILS = %w[
    david.carey@hmrc.gov.uk
    james.carter1@hmrc.gov.uk
  ].freeze

  UID_PREFIX = "migration_hmrc_admin_user_".freeze

  def up
    HMRC_USER_EMAILS.each do |email|
      next if User.exists?(email: email)

      User.create!(
        uid: migration_uid_for(email),
        name: name_from_email(email),
        email: email,
        disabled: false,
        remotely_signed_out: false,
        role: User::HMRC_ADMIN,
      )
    end
  end

  def down
    HMRC_USER_EMAILS.each do |email|
      user = User.find_by(email: email, uid: migration_uid_for(email))
      user&.destroy!
    end
  end

  private

  def migration_uid_for(email)
    "#{UID_PREFIX}#{email.split("@").first}"
  end

  def name_from_email(email)
    email.split("@").first.tr(".", " ").titleize
  end
end
