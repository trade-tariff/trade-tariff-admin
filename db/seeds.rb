# Basic Auth User - persisted static user for basic authentication
# This user has technical_operator role for admin access
User.basic_auth_user!.tap do |user|
  user.role = User::TECHNICAL_OPERATOR
  user.save!
end

# Winston user (legacy)
User.find_or_initialize_by(uid: 'winston', email: 'winston@alphagov.co.uk').tap do |user|
  user.name = 'Winston'
  user.version = 1
  user.role = User::HMRC_ADMIN
  user.save!
end
