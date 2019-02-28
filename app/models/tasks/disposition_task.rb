class DispositionTask < GenericTask
  class << self
    def create_disposition_task!(appeal, parent, hearing)
      DispositionTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )

      if parent.is_a? HearingTask
        HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent)
      end
    end
  end
end
