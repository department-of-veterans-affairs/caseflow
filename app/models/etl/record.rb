# frozen_string_literal: true

# abstract base class for all ETL:: models

class ETL::Record < ApplicationRecord
  self.abstract_class = true
  establish_connection :"etl_#{Rails.env}"
end
