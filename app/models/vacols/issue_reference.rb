# frozen_string_literal: true

class VACOLS::IssueReference < VACOLS::Record
  self.table_name = "#{Rails.application.config.vacols_db_name}.issref"
end
