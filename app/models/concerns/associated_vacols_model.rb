module AssociatedVacolsModel
  extend ActiveSupport::Concern

  module ClassMethods
    def vacols_attr_accessor *fields
      fields.each do |field|
        define_method field do
          check_and_load_vacols_data!
          instance_variable_get("@#{field}".to_sym)
        end

        define_method "#{field}=" do |value|
          check_and_load_vacols_data!
          instance_variable_set("@#{field}".to_sym, value)
        end
      end
    end
  end

  def set_from_vacols(values)
    values.each do |key, value|
      setter = self.method("#{key}=")
      setter.call(value)
    end
  end

  def check_and_load_vacols_data!
    unless @fetched_vacols_data
      # Fetch data from vacols
      @fetched_vacols_data = true
      self.class.repository.load_vacols_data(self)
    end
  end
end
