class EvidenceSubmissionWindowTask < GenericTask
  def on_complete
    RootTask.create_vso_subtask!(appeal, parent)
    super
  end
end
