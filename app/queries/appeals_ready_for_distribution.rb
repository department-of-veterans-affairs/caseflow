class AppealsReadyForDistribution
  def self.process
    ready_appeals = []
    docket_coordinator = DocketCoordinator.new

    docket_coordinator.dockets
      .flat_map { |sym, docket| docket.ready_to_distribute_appeals }
    # ready_appeals
  end
end
