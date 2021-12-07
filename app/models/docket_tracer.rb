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

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: docket_tracers
#
#  id                    :integer          not null, primary key
#  ahead_and_ready_count :integer
#  ahead_count           :integer
#  month                 :date             indexed => [docket_snapshot_id]
#  created_at            :datetime
#  updated_at            :datetime         indexed
#  docket_snapshot_id    :integer          indexed => [month]
#
# Foreign Keys
#
#  fk_rails_a0ad24f3ab  (docket_snapshot_id => docket_snapshots.id)
#
