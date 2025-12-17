# Basic Auth User - persisted static user for basic authentication
# This user can have roles switched as needed
User.basic_auth_user!.tap do |user|
  # Start with GUEST role by default, can be changed later
  user.remove_role(user.current_role) if user.current_role && user.current_role != User::GUEST
  user.add_role(User::GUEST) unless user.has_role?(User::GUEST)
end

# Winston user (legacy)
User.new { |u|
  u.name = 'Winston'
  u.uid = 'winston'
  u.version = 1
  u.email = 'winston@alphagov.co.uk'
}.save.tap do |user|
  user.remove_role(user.current_role) if user.current_role
  user.add_role(User::HMRC_ADMIN)
end
