class Issue
  include ActiveModel::Model

  attr_accessor :program, :description, :disposition, :new_material

  def non_new_material_allowed?
    !new_material && allowed?
  end

  def allowed?
    disposition == "Allowed"
  end
end
