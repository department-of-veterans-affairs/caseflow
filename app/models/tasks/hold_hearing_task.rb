class HoldHearingTask < GenericTask
  has_one :task_associated_object
  accepts_nested_attributes_for :task_associated_object

  class << self
    def create_hold_hearing_task!(appeal, parent, hearing)
      HoldHearingTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton,
        task_associated_object_attributes: {
          hearing: LegacyHearing.first
        }
      )
    end
  end
end
