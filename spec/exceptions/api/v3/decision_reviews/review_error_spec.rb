# frozen_string_literal: true

context Api::V3::DecisionReviews::ReviewError do
  let(:intake) do
    intake = Intake.build(
      user: build_stubbed(:user),
      search_term: "64205050",
      form_type: "higher_level_review"
    )
    intake.detail = HigherLevelReview.new
    intake
  end

  context ".new" do
    it do
      expect(described_class.new(intake)).to be_a described_class
    end

    it "should have error code :intake_review_failed" do
      expect(described_class.new(intake).error_code).to eq(:intake_review_failed)
    end

    it "should have error code :cat" do
      intake_with_error_code = intake
      intake_with_error_code.error_code = :veteran_not_valid
      expect(described_class.new(intake_with_error_code).error_code).to eq("veteran_not_valid")
    end
  end
end
