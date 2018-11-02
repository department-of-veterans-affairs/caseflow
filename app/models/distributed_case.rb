class DistributedCase < ApplicationRecord
  belongs_to :distribution

  validates :distribution, :case_id, :docket, :priority, :genpop, :genpop_query, :ready_at, presence: true
  validates :docket_index, presence: true, if: :legacy_nonpriority

  private

  def legacy_nonpriority
    docket == "legacy" && !priority
  end
end
