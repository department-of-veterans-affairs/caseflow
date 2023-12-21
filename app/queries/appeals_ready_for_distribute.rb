class AppealsReadyForDistribute
  def self.process
    ready_appeals = []
    Appeal.find_each do |appeal|
      if appeal.ready_for_distribution?
        ready_appeals << appeal
      end
    end
    ready_appeals
  end
end
