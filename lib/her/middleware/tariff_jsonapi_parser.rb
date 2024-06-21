module Her
  module Middleware
    class TariffJsonapiParser < ParseJSON
      def parse(body)
        json = parse_json(body)

        included = json.fetch(:included, [])
        primary_data = json.fetch(:data, {})

        populate_relationships(included, included)
        populate_relationships(primary_data, included)

        {
          data: primary_data || {},
          errors: json[:errors] || [],
          metadata: json[:meta] || {},
        }
      end

      def on_complete(env)
        env[:body] = case env[:status]
                     when 204
                       {
                         data: {},
                         errors: [],
                         metadata: {},
                       }
                     else
                       parse(env[:body])
                     end
      end

      private

      def populate_relationships(resource_relationships, included)
        Array.wrap(resource_relationships).each do |resource|
          next if resource.blank?

          resource_relationships = resource.delete(:relationships) { {} }
          resource[:attributes].merge!(populate_relationship(resource_relationships, included))
        end
      end

      def populate_relationship(relationships, included)
        return {} if included.empty?

        {}.tap do |built|
          relationships.each do |rel_name, linkage|
            linkage_data = linkage.fetch(:data, {})
            next if linkage_data.nil?

            built_relationship = if linkage_data.is_a? Array
                                   linkage_data.map { |l| included.detect { |i| i.values_at(:id, :type) == l.values_at(:id, :type) } }.compact
                                 else
                                   included.detect { |i| i && (i.values_at(:id, :type) == linkage_data.values_at(:id, :type)) }
                                 end

            built[rel_name] = built_relationship
          end
        end
      end
    end
  end
end
