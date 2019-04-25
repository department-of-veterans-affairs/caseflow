# frozen_string_literal: true

class VACOLS::CAVCCaseDecision < VACOLS::Record
  self.table_name = "#{Rails.application.config.vacols_db_name}.cova"
  self.primary_key = "cvfolder"
end
