# frozen_string_literal: true

# This module starts the intial Intake creation and backfills the EventRecord
# when a Decision Review Created Event is triggered
module Events::DecisionReviewCreated::CreateIntake
  # This starts the process of the Intake creation and EventRecord backfill by passing in the event, user, and veteran
  # that was created in the DecisionReviewCreated Service.
  def self.process!(event:, user:, veteran:)
    # create Intake
    intake = Intake.create!(veteran_file_number: veteran.file_number, user: user)
    # create EventRecord
    EventRecord.create!(event: event, backfill_record: intake)
    # Error Handling
  rescue Caseflow::Error::DecisionReviewCreatedIntakeError => error
    raise error
  end
end
