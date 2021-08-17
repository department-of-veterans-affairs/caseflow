# frozen_string_literal: true

##
# Task tracking work searching for decision documents related to VHA issues. CAMO coordinates this and can assign
# to a VHA Program office. When it's complete, they can return it to BVA Intake to recommend docketing or cancellation.

class VhaDocumentSearchTask < Task
  validates :parent, presence: true

  def available_actions(user)
    return [] unless user.organizations.include?(assigned_to)

    []
  end

  def self.label
    COPY::VHA_ASSESS_DOCUMENTATION_TASK_LABEL
  end
end
