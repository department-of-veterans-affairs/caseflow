# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

context Api::V3::DecisionReview::IntakeStatus, :postgres do
  let(:veteran_file_number) { "123456789" }

  def fake_intake
    intake = Intake.build(
      user: Generators::User.build,
      veteran_file_number: veteran_file_number,
      form_type: "higher_level_review"
    )
    intake.save
    intake
  end

  def fake_higher_level_review
    HigherLevelReview.create!(veteran_file_number: veteran_file_number)
  end

  context "#to_json" do
    subject { Api::V3::DecisionReview::IntakeStatus.new(intake) }
    it("returns a properly formatted hash") do
      intake = fake_intake
      decision_review = fake_higher_level_review

      uuid = "cat"
      decision_review.stub(:uuid) { uuid }

      asyncable_status = "dog"
      decision_review.stub(:asyncable_status) { asyncable_status }

      intake.detail = decision_review

      intake_status = Api::V3::DecisionReview::IntakeStatus.new(intake)

      expect(intake_status).to be_truthy
      expect(intake.detail).to be_truthy
      expect(intake_status.to_json).to be_truthy
      expect(intake_status.to_json[:data][:type]).to eq(decision_review.class.name)
      expect(intake_status.to_json[:data][:id]).to eq(uuid)
      expect(intake_status.to_json[:data][:atributes][:status]).to eq(asyncable_status)
    end
  end
end
