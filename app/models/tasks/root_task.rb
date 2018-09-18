class RootTask < Task
  after_initialize :set_assignee

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def when_child_task_completed; end

  class << self
    def create_root_and_sub_tasks!(appeal)
      root_task = create!(appeal_id: appeal.id, appeal_type: appeal.class.name)
      create_vso_subtask!(appeal, root_task)
    end

    private

    def create_vso_subtask!(appeal, parent)
      appeal.vsos.each do |vso_organization|
        GenericTask.create(appeal: appeal, parent: parent, status: "in_progress", assigned_to: vso_organization)
      end
    end
  end
end
