class Records::Folder < ActiveRecord::Base
  self.table_name = 'vacols.folder'
  self.primary_key = 'ticknum'

  def file_type
    if ['Y', '1', '0'].include?(tivbms)
      'VBMS'
    elsif tisubj == 'Y'
      'VVA'
    else
      'Paper'
    end
  end
end