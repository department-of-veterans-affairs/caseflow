class Idt::V1::TaskSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end

  attribute :added_by_first_name
  attribute :added_by_middle_name
  attribute :added_by_last_name 
  attribute :written_by_first_name do 
    object.attorney_first_name
  end
  attribute :written_by_middle_name do 
    object.attorney_middle_name
  end
  attribute :written_by_last_name do 
    object.attorney_last_name
  end
  attribute :document_id 
end