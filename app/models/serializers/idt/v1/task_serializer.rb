class Idt::V1::TaskSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end
  attribute :written_by do
    attorney_id = object.attorney_id

    attorney_id ? AttorneyRepostory.find_by_attorney_id(attorney_id).sdomainid : ""
  end
  attribute :document_id
end
