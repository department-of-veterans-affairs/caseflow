class ChangeGenericTasksAssignedToVsosToIhps < ActiveRecord::Migration[5.1]
  def up
    GenericTask.joins("JOIN organizations ON assigned_to_id=organizations.id").
      where("assigned_to_type=?", "Organization").
      where("organizations.type=?", "Vso").
      update_all(type: "InformalHearingPresentationTask")
  end
end
