class TakeDocketSnapshotJob < ActiveJob::Base
  queue_as :low_priority

  def perform
    DocketSnapshot.create
  end
end
