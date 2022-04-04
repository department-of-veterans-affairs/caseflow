module GovDelivery::TMS::InstanceResource
  def self.included(base)
    base.send(:include, GovDelivery::TMS::Base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
  end

  attr_accessor :response

  module ClassMethods
    ##
    # Writeable attributes are sent on POST/PUT.
    #
    def writeable_attributes(*attrs)
      @writeable_attributes ||= []
      if attrs.any?
        @writeable_attributes.map!(&:to_sym).concat(attrs).uniq! if attrs.any?
        setup_attributes(@writeable_attributes, false)
      end
      @writeable_attributes
    end

    ##
    # Linkable attributes are sent on POST/PUT.
    #
    def linkable_attributes(*attrs)
      @linkable_attributes ||= []
      if attrs.any?
        @linkable_attributes.map!(&:to_sym).concat(attrs).uniq! if attrs.any?
      end
      @linkable_attributes
    end

    ##
    # Readonly attributes don't get POSTed.
    # (timestamps are included by default)
    #
    def readonly_attributes(*attrs)
      @readonly_attributes ||= [:created_at, :updated_at, :completed_at]
      if attrs.any?
        @readonly_attributes.map!(&:to_sym).concat(attrs).uniq!
        setup_attributes(@readonly_attributes, true)
      end
      @readonly_attributes
    end

    ##
    # Nullable attributes are sent as null in the request
    #
    def nullable_attributes(*attrs)
      @nullable_attributes ||= []
      if attrs.any?
        @nullable_attributes.map!(&:to_sym).concat(attrs).uniq! if attrs.any?
      end
      @nullable_attributes
    end

    ##
    # For collections that are represented as attributes (i.e. inline, no href)
    #
    # @example
    #     collection_attributes :recipients
    #
    def collection_attributes(*attrs)
      @collection_attributes ||= []
      if attrs.any?
        @collection_attributes.map!(&:to_sym).concat(attrs).uniq!
        @collection_attributes.each { |a| setup_collection(a) }
      end
      @collection_attributes
    end

    def custom_class_names
      @custom_class_names ||= {}
    end

    ##
    # For collections that are represented as attributes (i.e. inline, no href)
    # and that have a class name other than the one we would infer.
    #
    # @example
    #    collection_attributes :recipients, 'EmailRecipient'
    #
    def collection_attribute(attr, tms_class)
      @collection_attributes ||= []
      @collection_attributes.push(attr).uniq!
      setup_collection(attr, GovDelivery::TMS.const_get(tms_class))
    end

    ##
    # Read-only collection attributes don't get POSTed.
    # Use this for collections that are represented as attributes, but cannot be modified.
    #
    # @example
    #      readonly_collection_attribute :opens
    #
    def readonly_collection_attribute(attr, tms_class)
      @readonly_collection_attributes ||= []
      @readonly_collection_attributes.push(attr).uniq!
      setup_collection(attr, GovDelivery::TMS.const_get(tms_class))
    end

    def setup_attributes(attrs, readonly = false)
      attrs.map(&:to_sym).each do |property|
        send :define_method, :"#{property}=", &lambda { |v| @attributes[property] = v } unless readonly
        send :define_method, property.to_sym, &lambda { @attributes[property] }
      end
    end

    def setup_collection(property, klass = nil)
      if klass
        custom_class_names[property] = klass
      else
        klass ||= GovDelivery::TMS.const_get(property.to_s.capitalize)
      end

      send :define_method, property.to_sym, &lambda { @attributes[property] ||= klass.new(self.client, nil, nil) }
    end
  end

  module InstanceMethods
    attr_reader :links

    def initialize(client, href = nil, attrs = nil)
      super(client, href)
      @attributes = {}
      @links = {}
      set_attributes_from_hash(attrs) if attrs
    end

    attr_reader :attributes

    def get(params={})
      fail GovDelivery::TMS::Errors::InvalidGet if self.new_record?
      process_response(client.get(href, params), :get) && self
    end
    alias_method :get!, :get

    def post
      self.errors = nil
      process_response(client.post(self), :post)
    end

    def post!
      post || fail(GovDelivery::TMS::Errors::InvalidPost.new(self))
    end

    def put
      process_response(client.put(self), :put)
    end

    def put!
      process_response(client.put(self), :put) || fail(GovDelivery::TMS::Errors::InvalidPut.new(self))
    end

    def delete
      process_response(client.delete(href), :delete)
    end

    def delete!
      process_response(client.delete(href), :delete) || fail(GovDelivery::TMS::Errors::InvalidDelete.new(self))
    end

    def to_s
      "<#{self.class.inspect}#{' href=' + href if href} attributes=#{@attributes.inspect}>"
    end

    def to_json
      json_hash = {}
      self.class.writeable_attributes.each do |attr|
        json_hash[attr] = send(attr)
      end
      self.class.collection_attributes.each do |coll|
        json_hash[coll] = send(coll).to_json
      end
      self.class.linkable_attributes.reject { |attr| @links[attr].nil? }.each do |attr|
        json_hash[:_links]       ||= {}
        json_hash[:_links][attr] = @links[attr]
      end
      json_hash.reject do |key, value|
        value.nil? && !self.class.nullable_attributes.include?(key)
      end
    end

    protected

    def relation_class(rel)
      self.class.custom_class_names[rel.to_sym] || super
    end

    def process_response(response, method)
      self.response = response
      error_class   = GovDelivery::TMS::Errors.const_get("Invalid#{method.to_s.capitalize}")
      case response.status
      when 204
        return true
      when 200..299
        set_attributes_from_hash(response.body) if response.body.is_a?(Hash)
        @links = {}
        self.new_record = false
        return true
      when 401
        fail error_class.new('401 Not Authorized')
      when 404
        fail(error_class.new("Can't POST to #{href}"))
      when 500..599
        fail(GovDelivery::TMS::Errors::ServerError.new(response))
      else # 422?
        self.errors = response.body['errors'] if response.body['errors']
      end
      false
    end

    def set_attributes_from_hash(hash)
      hash.reject { |k, _| k =~ /^_/ }.each do |property, value|
        if self.class.collection_attributes.include?(property.to_sym)
          klass                        = self.class.custom_class_names[property] || GovDelivery::TMS.const_get(property.to_s.capitalize)
          @attributes[property.to_sym] = klass.new(client, nil, value)
        else
          @attributes[property.to_sym] = value
        end
      end
      self.errors = hash['errors']
      parse_links(hash['_links'])
    end
  end
end
