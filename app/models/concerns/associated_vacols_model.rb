module AssociatedVacolsModel
  extend ActiveSupport::Concern

  module ClassMethods
    # vacols_attr_accessors will lazy load the underlying data from the VACOLS DB upon first call
    #
    # For example, appeal = Appeal.find(id) will *not* make any calls to load the data from VACOLS,
    # but soon as we call appeal.veteran_first_name, it will trigger the VACOLS DB lookup and fill in
    # all instance variables for the appeal. Further requests will pull the values from memory and not
    # do subsequent VACOLS DB lookups
    def vacols_attr_accessor(*fields)
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

  # Setter method for assigning a hash of values
  # to their corresponding instance variables
  def assign_from_vacols(values)
    values.each do |key, value|
      setter = method("#{key}=")
      setter.call(value)
    end
  end

  # TODO(jd): consider adding a more sophisticated caching mechanism.
  # Right now we are setting the @fetched_vacols_data to true before knowing
  # if the DB request to VACOLS succeeded. This is required to avoid an infinite
  # loop within the setters, but will not properly handle the case of VACOLS
  # returning an error
  def check_and_load_vacols_data!
    return if @fetched_vacols_data

    # Fetch and cache values from VACOLS
    @fetched_vacols_data = true
    self.class.repository.load_vacols_data(self)
  end
end
