class DistributedCase < ApplicationRecord
  belongs_to :distribution

  validates :distribution, :case_id, :docket, :priority, :genpop, :genpop_query, presence: true
  validates :docket_date, presence: true, unless: :priority
  validates :docket_index, presence: true, if: :legacy_nonpriority
  validates :ready_date, presence: true, if: :priority

  private

  def legacy_nonpriority
    docket == "legacy" && !priority
  end
end
