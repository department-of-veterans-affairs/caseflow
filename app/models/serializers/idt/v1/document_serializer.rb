class Idt::V1::DocumentSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end
  attribute :written_by do
    object.written_by_css_id ? User.find_by(css_id: object.written_by_css_id).full_name : ""
  end
  attribute :document_id
end
