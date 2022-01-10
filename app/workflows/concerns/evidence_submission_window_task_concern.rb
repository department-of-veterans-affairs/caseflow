# frozen_string_literal: true

module EvidenceSubmissionWindowTaskConcern
  extend ActiveSupport::Concern

  def evidence_submission_window_task(appeal, source_task, creation_params)
    unless creation_params["hold_end_date"]
      fail "Expecting hold_end_date creation parameter for EvidenceSubmissionWindowTask from #{source_task.id}"
    end

    # Ensure we properly handle time zone of submitted end date
    evidence_submission_hold_end_date = Time.find_zone("UTC").parse(creation_params["hold_end_date"])

    if appeal.docket_type == "hearing"
      excluded_attrs = %w[status closed_at placed_on_hold_at]
      new_task = source_task.copy_with_ancestors_to_stream(
        appeal,
        new_attributes: { end_date: evidence_submission_hold_end_date },
        extra_excluded_attributes: excluded_attrs
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
