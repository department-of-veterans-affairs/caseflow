# frozen_string_literal: true

class DocketTracer < CaseflowRecord
  belongs_to :docket_snapshot

  delegate :docket_count, :latest_docket_month, to: :docket_snapshot

  def at_front
    month <= latest_docket_month
  end

  def to_hash
    {
      front: at_front,
      total: docket_count,
      ahead: ahead_count,
      ready: ahead_and_ready_count,
      month: month,
      docketMonth: latest_docket_month,
      eta: nil
    }
  end
end
