# frozen_string_literal: true

# Shared methods of SameAppealSubstitutionTasksFactory and InitialTasksFactory workflows
module TasksFactoryConcern
  extend ActiveSupport::Concern

  EXCLUDED_ATTRS = %w[status closed_at placed_on_hold_at].freeze
  def create_evidence_submission_window_task(appeal, source_task, creation_params)
    unless creation_params["hold_end_date"]
      fail "Expecting hold_end_date creation parameter for EvidenceSubmissionWindowTask from #{source_task.id}"
    end

    # Ensure we properly handle time zone of submitted end date
    evidence_submission_hold_end_date = Time.find_zone("UTC").parse(creation_params["hold_end_date"])
    fail Caseflow::Error::InvalidParameter, parameter: "hold_end_date" if evidence_submission_hold_end_date.nil?

    if appeal.hearing_docket?
      new_task = source_task.copy_with_ancestors_to_stream(
        appeal,
        new_attributes: { end_date: evidence_submission_hold_end_date },
        extra_excluded_attributes: EXCLUDED_ATTRS
      )
      EvidenceSubmissionWindowTask.create_timer(new_task)
    else
      EvidenceSubmissionWindowTask.create!(
        appeal: appeal,
        parent: distribution_task,
        end_date: evidence_submission_hold_end_date
      )
    end
  end
end
