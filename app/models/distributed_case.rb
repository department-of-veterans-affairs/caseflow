# frozen_string_literal: true

class DistributedCase < CaseflowRecord
  belongs_to :distribution
  belongs_to :task

  validates :case_id, :distribution, :docket, :ready_at, presence: true
  validates :genpop, inclusion: [true, false], if: :docket_has_hearing_option
  validates :genpop_query, presence: true, if: :docket_has_hearing_option
  validates :task_id, presence: true, if: :ama_docket
  validates :docket_index, presence: true, if: :legacy_nonpriority
  validates :priority, inclusion: [true, false]

  private

  def docket_has_hearing_option
    %w[legacy hearing].include?(docket)
  end

  def ama_docket
    %w[direct_review evidence_submission hearing].include?(docket)
  end

  def legacy_nonpriority
    docket == "legacy" && !priority
  end
end
