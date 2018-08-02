class Idt::V1::AppealDetailsSerializer < ActiveModel::Serializer
  # TODO: serialize AMA appeals with this serializer
  def id
    object.vacols_id
  end

  attribute :veteran_first_name 
  attribute :veteran_middle_name do
    object.veteran_middle_initial
  end
  attribute :veteran_last_name
  attribute :veteran_is_appellant do
  end

  a

  atttribute :appellant do
    {} if object.fadfas

    {
      appellant_first_name
      appellant_middle_name
      appellant_first_name
    }

  end


  attribute :veteran_middle_name do
    object.veteran_middle_initial
  end
  attribute :veteran_last_name
  attribute :file_number do
    object.sanitized_vbms_id
  end
  attribute :docket_number
  attribute :number_of_issues do
    object.issues.length
  end
  attribute :
  attribute :appellant_first_name
  attribute :appellant_middle_name
  attribute :appellant_last_name
end
