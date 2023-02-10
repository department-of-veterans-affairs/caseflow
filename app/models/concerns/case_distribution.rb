# frozen_string_literal: true

module CaseDistribution
  extend ActiveSupport::Concern

  delegate :dockets,
           :docket_proportions,
           :priority_count,
           :nonpriority_count,
           :direct_review_due_count,
           :total_batch_size,
           :legacy_hearing_priority_count,
           :legacy_hearing_nonpriority_count,
           to: :docket_coordinator

  private

  def docket_coordinator
    @docket_coordinator ||= DocketCoordinator.new
  end

  def collect_appeals
    appeals = yield
    @rem -= appeals.count
    @appeals += appeals
    appeals
  end

  def priority_target
    proportion = [priority_count.to_f / total_batch_size, 1.0].reject(&:nan?).min
    (proportion * batch_size).ceil
  end
end
