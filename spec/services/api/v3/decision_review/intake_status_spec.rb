# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

context Api::V3::DecisionReview::IntakeStatus, :postgres do
  let(:veteran_file_number) { "123456789" }

  def fake_intake(detail = nil)
    Intake.create!(
      user: Generators::User.build,
      veteran_file_number: veteran_file_number,
      detail: detail,
    )
  end

  def fake_higher_level_review
    HigherLevelReview.create!(veteran_file_number: veteran_file_number)
  end

  context "#to_json" do
    subject { Api::V3::DecisionReview::IntakeStatus.new(intake) }
    it("returns a properly formatted hash") do
      decision_review = fake_higher_level_review

      asyncable_status = "dog"
      allow(decision_review).to receive(:asyncable_status) { asyncable_status }

      uuid = "cat"
      allow(decision_review).to receive(:uuid) { uuid }

      intake = fake_intake(decision_review)

      intake_status = Api::V3::DecisionReview::IntakeStatus.new(intake, reload: false)

      expect(intake_status.to_json[:data][:type]).to eq(decision_review.class.name)
      expect(intake_status.to_json[:data][:attributes][:status]).to eq(asyncable_status)
      expect(intake_status.to_json[:data][:id]).to eq(uuid)
    end
  end
end
