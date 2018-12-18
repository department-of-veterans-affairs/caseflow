class DistributionTask < Task
  def ready_for_distribution?
    in_progress? && all_children_complete
  end
end
