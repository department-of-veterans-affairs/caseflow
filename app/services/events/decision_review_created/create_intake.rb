# frozen_string_literal: true

# This module starts the intial Intake creation and backfills the EventRecord
# when a Decision Review Created Event is triggered
module Events::DecisionReviewCreated::CreateIntake
  # This starts the process of the Intake creation and EventRecord backfill by passing in the event, user, and veteran
  # that was created in the DecisionReviewCreated Service.
  def self.process!(event:, user:, veteran:, parser:)
    # create Intake
    intake = Intake.create!(veteran_file_number: veteran.file_number,
                            user: user,
                            started_at: parser.intake_started_at,
                            completion_started_at: parser.intake_completion_started_at,
                            completed_at: parser.intake_completed_at,
                            completion_status: parser.intake_completion_status,
                            type: parser.intake_type,
                            detail_type: parser.intake_detail_type)
    # create EventRecord
    EventRecord.create!(event: event, evented_record: intake)

    intake
    # Error Handling
  rescue Caseflow::Error::DecisionReviewCreatedIntakeError => error
    raise error
  end
end
