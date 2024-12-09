module RedactedAttributesConcern
  extend ActiveSupport::Concern

  included do
    after_initialize :redact_instance_methods
  end

  module ClassMethods
    def redact_attributes
      attrs_to_redact.each do |attr|
        attr_name = attr[:name]

        if attr[:alias] && attr[:class_method]
          alias_method "unredacted_#{attr_name}".to_sym, attr_name
        end

        override_method_for_redaction(attr_name, attr[:alias])
      end
    end

    def attrs_to_redact
      return self.name.constantize::ATTRS_TO_REDACT_FROM_NON_BOARD_USERS if const_defined?(:ATTRS_TO_REDACT_FROM_NON_BOARD_USERS)

      []
    end

    def override_method_for_redaction(name, aliased_method)
      define_method name do
        return nil if RequestStore[:current_user]&.non_board_employee?

        aliased_method ? send("unredacted_#{name}".to_sym) : attributes[name.to_s]
      end
    end
  end

  # Overrides instance methods once object is instantiated and the original ones are available
  def redact_instance_methods
    self.class.attrs_to_redact.each do |attr|
      attr_name = attr[:name]

      if attr[:alias] && respond_to?(attr_name)
        original_method_name = "unredacted_#{attr_name}".to_sym

        unless respond_to?(original_method_name)
          self.class.alias_method original_method_name, attr_name

          self.class.override_method_for_redaction(attr_name, attr[:alias])
        end
      end
    end
  end
end
