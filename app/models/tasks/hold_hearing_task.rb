class HoldHearingTask < GenericTask
  class << self
    def create_hold_hearing_task!(appeal, parent)
      HoldHearingTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )
    end
  end
end
