class Idt::V1::DocumentSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end
  attribute :written_by do
    [object.written_by_first_name, object.written_by_last_name].join(" ")
  end
  attribute :document_id
end
