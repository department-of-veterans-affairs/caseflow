class DistributedCase < ApplicationRecord
  belongs_to :distribution
  belongs_to :task

  validates :distribution, :case_id, :docket, :ready_at, presence: true
  validates :genpop, inclusion: [true, false], if: :hearing_docket
  validates :genpop_query, presence: true, if: :hearing_docket
  validates :task_id, presence: true, if: :ama_docket
  validates :docket_index, presence: true, if: :legacy_nonpriority
  validates :priority, inclusion: [true, false]

  private

  def hearing_docket
    %w[legacy hearing].include?(docket)
  end

  def ama_docket
    %w[direct_review evidence_submission hearing].include?(docket)
  end

  def legacy_nonpriority
    docket == "legacy" && !priority
  end
end
