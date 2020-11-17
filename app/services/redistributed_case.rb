# frozen_string_literal: true

class RedistributedCase
  class CannotRedistribute < StandardError; end

  # case_id is synonymous with vacols_id
  def initialize(case_id:, new_distribution:)
    @case_id = case_id
    @new_distribution = new_distribution
  end

  def allow!
    unless legacy_appeal
      alert_case_not_found
      return false
    end

    if ok_to_redistribute?
      rename_existing_distributed_case!
    elsif legacy_appeal_relevant_tasks.any?(&:open?)
      fix_vacols_case_location(LegacyAppeal::LOCATION_CODES[:caseflow])
      false
    else
      alert_existing_distributed_case_not_unique
      fix_vacols_case_location(LegacyAppeal::LOCATION_CODES[:case_storage])
      false
    end
  end

  def ok_to_redistribute?
    # If there is an open task, the case should be located in "CASEFLOW" and not redistributed.
    return false if legacy_appeal_relevant_tasks.any?(&:open?)
    # redistribute if there are no relevant tasks or if they are all completed or cancelled
    return true if legacy_appeal_relevant_tasks.all?(&:closed?)

    false
  end

  private

  attr_reader :case_id, :new_distribution

  def existing_distributed_case
    @existing_distributed_case ||= DistributedCase.find_by(case_id: case_id)
  end

  def rename_existing_distributed_case!
    existing_distributed_case.rename_for_redistribution!
  end

  def alert_case_not_found
    error = CannotRedistribute.new("Case not found")
    Raven.capture_exception(
      error,
      extra: {
        vacols_id: case_id
      }
    )
  end

  # send to Sentry but do not raise exception.
  def alert_existing_distributed_case_not_unique
    error = CannotRedistribute.new("DistributedCase already exists")
    Raven.tags_context judge: new_distribution.judge.css_id
    Raven.capture_exception(
      error,
      tags: { vacols_id: case_id },
      extra: {
        location: legacy_appeal.location_code,
        previous_location: legacy_appeal.location_history.last.summary
      }
    )
  end

  def fix_vacols_case_location(location)
    legacy_appeal.case_record.update_vacols_location!(location)
  end

  def legacy_appeal
    @legacy_appeal ||= LegacyAppeal.find_by(vacols_id: case_id)
  end

  def legacy_appeal_relevant_tasks
    @legacy_appeal_relevant_tasks ||= legacy_appeal.tasks.reject do |task|
      task.is_a?(TrackVeteranTask) || task.is_a?(RootTask)
    end
  end
end
