class Idt::V1::TaskSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end
  attribute :assigned_by do
    css_id = object.assigned_by_css_id

    css_id ? User.find_by(css_id: object.assigned_by_css_id).full_name : ""
  end
  attribute :written_by do
    css_id = object.assigned_to_css_id

    css_id ? User.find_by(css_id: object.assigned_to_css_id).full_name : ""
  end
  attribute :document_id
end
