class Records::Folder < ActiveRecord::Base
  self.table_name = "vacols.folder"
  self.primary_key = "ticknum"
end
