# frozen_string_literal: true

##
# Task tracking work searching for decision documents related to VHA issues. CAMO coordinates this and can assign
# to a VHA Program office. When it's complete, they can return it to BVA Intake to recommend docketing or cancellation.

class VhaDocumentSearchTask < Task
  validates :parent, presence: true

  def available_actions(user)
    return [] unless assigned_to.user_has_access?(user)

    [Constants.TASK_ACTIONS.VHA_ASSIGN_TO_PROGRAM_OFFICE.to_h,
     Constants.TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.to_h]
  end

  def self.label
    COPY::VHA_ASSESS_DOCUMENTATION_TASK_LABEL
  end
end
