module Her
  module Model
    module PropagateErrors
      extend ActiveSupport::Concern

      def save
        super.tap(&method(:propagate_errors))
      end

    private

      def propagate_errors(success)
        return if success || !@response_errors&.any?

        @response_errors.each do |err|
          next unless err.is_a?(Hash)
          next if err[:title].blank?

          pointer = err.dig(:source, :pointer).to_s
          next unless pointer.start_with? '/data/attributes/'

          attribute = pointer.gsub(%r{\A/data/attributes/}, '')
          msg = "#{self.class.human_attribute_name(attribute)} #{err[:title]}"
          errors.add(attribute, msg)
        end
      end
    end
  end
end
