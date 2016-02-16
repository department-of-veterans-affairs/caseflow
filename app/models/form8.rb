class Form8
  include ActiveModel::Model
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :vacols_id, :appellant, :appellant_relationship, :file_number

  def self.new_from_appeal(appeal)
    new(
      vacols_id: appeal.vacols_id,
      appellant: appeal.correspondent.appellant_name,
      appellant_relationship: appeal.correspondent.appellant_relationship,
      file_number: appeal.vbms_id
    )
  end
end
