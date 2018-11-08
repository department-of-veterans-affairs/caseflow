class DistributedCase < ApplicationRecord
  belongs_to :distribution

  validates :distribution, :case_id, :docket, :genpop_query, :ready_at, presence: true
  validates :priority, :genpop, inclusion: [true, false]
  validates :docket_index, presence: true, if: :legacy_nonpriority

  private

  def legacy_nonpriority
    docket == "legacy" && !priority
  end
end
