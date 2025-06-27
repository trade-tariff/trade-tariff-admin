module ApiEntity
  extend ActiveSupport::Concern

  class CollectionProxy < SimpleDelegator
    def initialize(collection, casted_by, class_name)
      @collection = collection
      @casted_by = casted_by
      @class_name = class_name

      super @collection
    end

    def find(id)
      result = @collection.find { |entry| entry.to_param.to_s == id.to_s }

      return result if result.present?

      raise Faraday::ResourceNotFound, 'Resource not found'
    end

    def build(attributes = {})
      @class_name.constantize.new(casted_by: @casted_by).build(attributes)
    end
  end

  included do
    include ActiveModel::Conversion
    include ActiveModel::Validations
    extend  ActiveModel::Naming

    attributes :resource_id, :resource_type, :casted_by

    delegate :relationships, :api, :parse_jsonapi, to: :class
    delegate :[], :dig, to: :attributes

    def inspect
      attrs = if defined?(@attributes) && @attributes.any?
                attributes_for_inspect
              else
                instance_variables_for_inspect
              end

      inspection = attrs.any? ? attrs.join(', ') : 'not initialised'

      "#<#{self.class.name.presence || self.class} #{inspection}>"
    end

    def attributes
      @attributes ||= {}
    end

    def to_param
      resource_id
    end

    alias_method :id, :to_param

    def resource_type
      @attributes['resource_type'] || self.class.model_name.element
    end
  end

  def initialize(attributes = {})
    @attributes = HashWithIndifferentAccess.new(attributes)

    self.attributes = attributes
  end

  def attributes=(attributes = {})
    @attributes = attributes.to_h.with_indifferent_access

    assign_attributes(@attributes)
  end

  def assign_attributes(attributes = {})
    attributes.each do |name, value|
      next unless respond_to?(:"#{name}=")

      public_send(:"#{name}=", value)
    end

    @attributes.merge!(attributes)
    @attributes
  end

  def build(attributes = {})
    assign_attributes(attributes)

    self
  end

  def update(attributes = {})
    build(attributes).save
  end

  def persisted?
    @persisted ||= resource_id.present?
  end

  def save
    resp = begin
      if persisted?
        api.patch(singular_path, serializable_hash)
      else
        api.post(singular_path, serializable_hash)
      end
    rescue Faraday::UnprocessableEntityError => e
      e.response
    end

    parsed = parse_jsonapi(resp)
    @attributes.merge!(parsed) if parsed.present?
    initialize_errors if self[:errors]

    self
  end

  def destroy
    api.delete(singular_path)
  end

  def serializable_hash
    TariffJsonapiSerializer.new(self).serializable_hash
  end

  def singular_path
    if self.class.set_singular_path?
      handle_provided_path(singular: true)
    else
      handle_calculated_path
    end
  end

  def collection_path
    if self.class.set_collection_path?
      handle_provided_path(singular: false)
    else
      handle_calculated_path
    end
  end

  def method_missing(method_name, *args, &block)
    attributes.key?(method_name) ? self[method_name] : super
  end

  def respond_to_missing?(method_name, include_private = false)
    attributes.key?(method_name) || super
  end

  def path_attributes
    @path_attributes ||= if self.class.set_singular_path?
                           self.class.singular_path.scan(/(:\w+)\/?/).flatten
                         else
                           []
                         end
  end

  def cleaned_path_attributes
    path_attributes.map { |path_attribute| path_attribute.sub(':', '') }
  end

private

  def initialize_errors
    self[:errors].each do |error|
      errors.add(
        error.dig('source', 'pointer').to_s.sub('/data/attributes/', ''),
        error['detail'],
      )
    end
  end

  def handle_provided_path(singular: false)
    path = self.class.singular_path.dup if singular
    path ||= self.class.collection_path.dup

    if path_attributes.any?
      path_attributes.map do |path_attribute|
        cleaned_path_attribute = path_attribute.sub(':', '')
        path_value = public_send(:[], cleaned_path_attribute).to_s
        path_value = path_value.presence || public_send(cleaned_path_attribute).to_s

        path_value = if path_value.blank? && casted_by.present?
                       if ":#{casted_by.model_name.element}_id" == path_attribute
                         casted_by.public_send(:id).to_s
                       else
                         casted_by.public_send(:[], path_attribute.sub(':', '')).to_s
                       end
                     else
                       path_value
                     end

        path.sub!(path_attribute, path_value)
      end
    end

    path
  end

  def handle_calculated_path
    return "admin/#{[self.class.name.underscore.pluralize, to_param].compact.join('/')}" if casted_by.blank?

    path_resources = []

    current = self
    loop do
      break if current.blank?

      path_resources << current
      current = current.casted_by
    end

    path = path_resources.reverse.each_with_object([]) do |resource, acc|
      acc << resource.model_name.element.pluralize
      acc << resource.to_param if resource.to_param
    end

    "admin/#{path.join('/')}"
  end

  def attributes_for_inspect
    @attributes.except(*(relationships.to_a + [:casted_by]))
               .map { |k, v| "#{k}: #{v.inspect}" }
  end

  def instance_variables_for_inspect
    instance_variables.without(%i[@attributes @casted_by])
                      .map { |k| k.to_s.sub('@', '') }
                      .select(&method(:respond_to?))
                      .map { |k| "#{k}: #{public_send(k).inspect}" }
  end

  module ClassMethods
    delegate :get, :post, to: :api

    def attribute(attribute)
      define_method(attribute) do
        attributes[attribute]
      end

      define_method("#{attribute}=") do |value|
        attributes[attribute] = value
      end
    end

    def attributes(*attribute_list)
      attribute_list.each do |resource_attribute|
        attribute resource_attribute
      end
    end

    def relationships
      @relationships ||= superclass.include?(ApiEntity) ? superclass.relationships.dup : []
    end

    def build(attributes = {})
      new attributes
    end

    def find(id, opts = {}, headers = {})
      id = id.to_s
      entity = new({ resource_id: id }.merge(opts))
      path = entity.singular_path

      opts = opts.except(*entity.cleaned_path_attributes)

      response = api.get(path, opts, headers)

      new parse_jsonapi(response)
    end

    def collection(opts = {})
      entity = build(opts)

      resp = api.get(
        entity.collection_path,
        opts.with_indifferent_access.except(:casted_by, *entity.cleaned_path_attributes),
      )

      collection = parse_jsonapi(resp)
      collection = collection.map do |entry_data|
        entry = new(entry_data)
        entry.assign_attributes(casted_by: opts[:casted_by]) if opts[:casted_by]
        entry
      end

      meta = handle_body(resp).fetch('meta', {})

      if meta['pagination'].present?
        collection = paginate_collection(collection, meta.fetch('pagination', {}))
      end

      CollectionProxy.new(collection, opts[:casted_by], name)
    end

    alias_method :all, :collection

    def has_one(association, opts = {})
      klass = if opts[:class_name].present?
                opts[:class_name].to_s.constantize
              else
                class_name = association.to_s.singularize.classify
                klass = namespace.present? ? namespace.const_get(class_name) : class_name.constantize
              end

      relationships << association

      define_method(association) do
        instance_variable_get("@#{association}").presence || klass.new(casted_by: self)
      end

      define_method("#{association}=") do |attributes|
        entity = klass.new((attributes.presence || {}).merge(casted_by: self))

        instance_variable_set("@#{association}", entity)
      end
    end

    def has_many(association, opts = {})
      klass = if opts[:class_name].present?
                opts[:class_name].to_s.constantize
              else
                class_name = association.to_s.singularize.classify
                klass = namespace.present? ? namespace.const_get(class_name) : class_name.constantize
              end

      relationships << association

      define_method(association) do
        instance_variable_get("@#{association}").presence || []
      end

      define_method("#{association}=") do |data|
        data = data.presence || []

        collection = data.map do |attributes|
          klass.new((attributes.presence || {}).merge(casted_by: self))
        end

        instance_variable_set("@#{association}", collection)
      end
    end

    def paginate_collection(collection, pagination)
      Kaminari.paginate_array(
        collection,
        total_count: pagination['total_count'],
      ).page(pagination['page']).per(pagination['per_page'])
    end

    def singular_path
      @singular_path ||= "admin/#{name.pluralize.underscore}/:id"
    end

    def set_singular_path(path)
      @singular_path = path
      @set_singular_path = true
    end

    def set_singular_path?
      @set_singular_path
    end

    def collection_path
      @collection_path ||= "admin/#{name.pluralize.underscore}"
    end

    def set_collection_path(path)
      @collection_path = path
      @set_collection_path = true
    end

    def set_collection_path?
      @set_collection_path
    end

    def api
      TradeTariffAdmin::ServiceChooser.api_client(@service)
    end

    def parse_jsonapi(resp)
      body = handle_body(resp)

      TariffJsonapiParser.new(body).parse if body.present?
    rescue TariffJsonapiParser::ParsingError
      raise UnparseableResponseError, resp
    end

    def namespace
      @namespace ||= name.split('::')[0...-1].join('::').constantize
    rescue NameError
      nil
    end

    def xi_only
      service('xi')
    end

    def uk_only
      service('uk')
    end

    def service(service)
      @service = service
    end

    def uk_only?
      @service == 'uk'
    end

    def xi_only?
      @service == 'xi'
    end

    private

    def handle_body(resp)
      body = resp.try(:body) || resp.try(:[], :body)

      return '' if body.blank?
      return JSON.parse(body) if body.is_a?(String)

      body
    end

    def handle_headers(resp)
      headers = resp.try(:headers) || resp.try(:[], :headers)

      return {} if headers.blank?

      headers
    end
  end
end
