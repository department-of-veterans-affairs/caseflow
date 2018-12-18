class DistributionTask < DistributionTask
	def ready_for_distribution?
		in_progress && children.empty? || children.all?(&:completed_at)
	end
end