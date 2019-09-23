# frozen_string_literal: true

class RedistributedCase
  class CannotRedistribute < StandardError; end

  def initialize(case_id:, new_distribution:)
    @case_id = case_id
    @new_distribution = new_distribution
  end

  def create!
    unless ok_to_redistribute?
      alert_existing_distributed_case_not_unique
      return
    end

    rename_existing_distributed_case!
  end

  def ok_to_redistribute?
    # must have previous history being worked in Caseflow
    return false unless legacy_appeal_relevant_tasks.any?

    # but all previous tasks must be closed (completed/cancelled)
    return false if legacy_appeal_relevant_tasks.any?(&:open?)

    true
  end

  private

  attr_reader :case_id, :new_distribution

  def existing_distributed_case
    @existing_distributed_case ||= DistributedCase.find_by(case_id: case_id)
  end

  def rename_existing_distributed_case!
    ymd = Time.zone.today.strftime("%F")
    existing_distributed_case.update!(case_id: "#{case_id}-redistributed-#{ymd}")
  end

  # send to Sentry but do not raise exception.
  def alert_existing_distributed_case_not_unique
    error = CannotRedistribute.new("DistributedCase #{case_id} already exists")
    Raven.capture_exception(error, extra: { vacols_id: case_id, judge: new_distribution.judge.css_id })
  end

  def legacy_appeal
    @legacy_appeal ||= LegacyAppeal.find_by(vacols_id: case_id)
  end

  def legacy_appeal_relevant_tasks
    legacy_appeal.tasks.reject { |task| task.type == "TrackVeteranTask" || task.type == "RootTask" }
  end
end
