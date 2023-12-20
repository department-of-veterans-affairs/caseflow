module RailsERD
  class Domain
    class << self
      # since we have 3 dbs we must override to specify a specific base class (NOT ActiveRecord::Base)
      def generate(options = {})
        base_class = ENV.fetch("ERD_BASE", "ApplicationRecord").constantize
        new base_class.descendants, options
      end
    end
  end
end
