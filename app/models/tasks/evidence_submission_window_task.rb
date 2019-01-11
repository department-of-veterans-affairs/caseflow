class EvidenceSubmissionWindowTask < GenericTask
  after_update :create_vso_subtask, if: :status_changed_to_completed_and_has_parent?

  def create_vso_subtask
    RootTask.create_vso_subtask!(appeal, parent)
  end
end
