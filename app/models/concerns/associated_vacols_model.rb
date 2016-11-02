module AssociatedVacolsModel
  extend ActiveSupport::Concern

  module ClassMethods
    # vacols_attr_accessors will lazy load the underlying data from the VACOLS DB upon first call
    #
    # For example, appeal = Appeal.find(id) will *not* make any calls to load the data from VACOLS,
    # but soon as we call appeal.veteran_first_name, it will trigger the VACOLS DB lookup and fill in
    # all instance variables for the appeal. Further requests will pull the values from memory and not
    # do subsequent VACOLS DB lookups
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
