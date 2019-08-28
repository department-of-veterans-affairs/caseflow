# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

context Api::V3::DecisionReview::IntakeStatus, :postgres do
  let(:intake) do
    intake = Intake.build(
      user: Generators::User.build,
      veteran_file_number: "64205050",
      form_type: "higher_level_review"
    )
    intake.detail = HigherLevelReview.new
    intake
  end

  context "#render_hash" do
    subject { Api::V3::DecisionReview::IntakeStatus.new(intake) }
    it("returns a properly formatted hash") do
      expect(subject.render_hash).to eq(
        json: {
          type: intake.detail_type,
          id: intake.detail.uuid,
          attributes: { status: intake.detail.asyncable_status }
        },
        status: :accepted
      )
    end
  end
end
