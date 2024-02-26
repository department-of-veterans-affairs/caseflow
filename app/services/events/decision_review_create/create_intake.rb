# frozen_string_literal: true

module Events::DecisionReviewCreate::CreateIntake
  # preview of call: Events::DecisionReviewCreate::CreateIntake.process!(event, veteran, user)
  # self.process! method
  # create Intake, args needed veteran.file_number and user: { user }
  # intake = Intake.create!(veteran_file_number: vetran.file_number, user: user)
  # create EventRecord by passing event: { event } and backfill_record: { intake } created
  # end

  # Error Handling
  # create custom error called DecisionReviewCreatedIntakeError
  # rescue Caseflow::Error::DecisionReviewCreatedIntakeError =>
  #   raise error
  # end
end
