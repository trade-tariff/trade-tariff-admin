# Winston user (legacy)
User.find_or_initialize_by(uid: 'winston', email: 'winston@alphagov.co.uk').tap do |user|
  user.name = 'Winston'
  user.version = 1
  user.role = User::HMRC_ADMIN
  user.save!
end
