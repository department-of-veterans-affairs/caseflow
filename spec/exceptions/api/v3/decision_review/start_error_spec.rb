# frozen_string_literal: true

require "rails_helper"

context Api::V3::DecisionReview::StartError do
  let(:intake) do
    intake = Intake.build(
      user: Generators::User.build,
      veteran_file_number: "64205050",
      form_type: "higher_level_review"
    )
    intake.detail = HigherLevelReview.new
    intake
  end

  context ".new" do
    subject { Api::V3::DecisionReview::StartError }
    it "creating the exception should not raise an exception" do
      expect { subject.new(intake) }.not_to raise_error
    end
    it "should have error code :intake_review_failed" do
      expect(subject.new(intake).error_code).to eq(:intake_start_failed)
    end
    it "should have error code :cat" do
      intake_with_error_code = intake
      intake_with_error_code.error_code = :veteran_not_valid
      expect(subject.new(intake_with_error_code).error_code).to eq("veteran_not_valid")
    end
  end
end

