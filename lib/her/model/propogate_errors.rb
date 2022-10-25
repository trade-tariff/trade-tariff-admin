module Her
  module Model
    module PropogateErrors
      extend ActiveSupport::Concern

      def save
        super.tap(&method(:propogate_errors))
      end

    private

      def propogate_errors(success)
        return if success || !@response_errors&.any?

        @response_errors.each do |err|
          next unless err.is_a?(Hash)
          next if err[:description].blank?

          pointer = err.dig(:source, :pointer).to_s
          next unless pointer.start_with? '/data/attributes/'

          errors.add pointer.gsub(%r{\A/data/attributes/}, ''), err[:description]
        end
      end
    end
  end
end
