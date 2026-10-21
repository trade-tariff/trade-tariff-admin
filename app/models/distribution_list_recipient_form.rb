# Validates an email address that a technical operator wants to subscribe to a
# distribution list. It is never persisted.
class DistributionListRecipientForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string

  validates :email,
            presence: { message: "Enter an email address" },
            length: { maximum: 254, message: "Email address must be 254 characters or fewer" },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "Enter an email address in the correct format, like name@example.com", allow_blank: true }

  def email=(value)
    super(value.to_s.strip.downcase.presence)
  end
end
