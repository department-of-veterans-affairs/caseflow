# frozen_string_literal: true

class CaseflowRecord < ApplicationRecord
  self.abstract_class = true

  # all caseflow db models should inherit from this class.
  # all vacols models inherit from VACOLS::Record
  # all etl models inherit from ETL::Record

  # In theory, this class should not need any additional code.
  # It's here to make generating documentation easier, by clearly
  # delineating db models via class inheritance.
end
