class Idt::V1::DocumentSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end
  attribute :written_by do
    attorney_id = object.written_by_attorney_id

    attorney_id ? AttorneyRepository.find_by_attorney_id(attorney_id).sdomainid : ""
  end
  attribute :document_id
end
