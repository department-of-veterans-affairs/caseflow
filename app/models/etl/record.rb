# frozen_string_literal: true

# abstract base class for all ETL:: models

class ETL::Record < ApplicationRecord
  self.abstract_class = true
  establish_connection :"etl_#{Rails.env}"

  class << self
    def sync_with_original(original)
      target = find_by_primary_key(original) || new
      target.attributes = original.attributes
      target
    end

    # the column on this class that refers to the origin class primary key
    # the default assumption is that the 2 classes share a primary key name (e.g. "id")
    def origin_primary_key
      primary_key
    end

    private

    def find_by_primary_key(original)
      pk = original[original.class.primary_key]
      find_by(origin_primary_key => pk)
    end
  end
end
