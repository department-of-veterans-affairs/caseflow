class Idt::V1::TaskSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end

  attribute :added_by_first_name
  attribute :added_by_middle_name
  attribute :added_by_last_name 
  attribute :written_by_first_name { task.attorney_first_name }
  attribute :written_by_middle_name { task.attorney_middle_name }
  attribute :written_by_last_name { task.attorney_last_name }  
  attribute :document_id 
end