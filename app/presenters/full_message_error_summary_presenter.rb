class FullMessageErrorSummaryPresenter
  def initialize(record)
    @record = record
  end

  def formatted_error_messages
    @record.errors.attribute_names.filter_map do |attribute|
      message = @record.errors.full_messages_for(attribute).first
      [attribute, message] if message.present?
    end
  end
end
