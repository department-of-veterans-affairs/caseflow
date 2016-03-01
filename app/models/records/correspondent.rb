class Records::Correspondent < ActiveRecord::Base
  self.table_name = 'vacols.corres'
  self.primary_key = 'stafkey'
end