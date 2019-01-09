class EvidenceSubmissionWindowTask < GenericTask
	def on_complete
  	create_vso_subtask!(appeal, parent)
  	super
	end
end
