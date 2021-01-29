# frozen_string_literal: true

context Api::V3::DecisionReviews::IntakeErrors do
  context ".render_hash" do
    let(:intake_start_failed_intake_error) do # status 422
      Api::V3::DecisionReviews::IntakeError.new(:intake_start_failed)
    end

    let(:veteran_not_accessible_intake_error) do # status 403
      Api::V3::DecisionReviews::IntakeError.new(:veteran_not_accessible)
    end

    let(:unknown_intake_error) { Api::V3::DecisionReviews::IntakeError.new } # status 500

    let(:not_an_intake_error) { StandardError.new }

    it "should return a properly formatted render hash with a status 422 (the highest one)" do
      expect(
        Api::V3::DecisionReviews::IntakeErrors.new(
          [intake_start_failed_intake_error, veteran_not_accessible_intake_error]
        ).render_hash
      ).to eq(
        json: { errors: [intake_start_failed_intake_error.to_h, veteran_not_accessible_intake_error.to_h] },
        status: [intake_start_failed_intake_error.status, veteran_not_accessible_intake_error.status].max
      )
    end

    it "should return a properly formatted render hash with a status 500 (the highest one)" do
      expect(
        Api::V3::DecisionReviews::IntakeErrors.new(
          [intake_start_failed_intake_error, unknown_intake_error]
        ).render_hash
      ).to eq(
        json: { errors: [intake_start_failed_intake_error.to_h, unknown_intake_error.to_h] },
        status: [intake_start_failed_intake_error.status, unknown_intake_error.status].max
      )
    end

    it "should raise an exception" do
      expect do
        Api::V3::DecisionReviews::IntakeErrors.new(
          [intake_start_failed_intake_error, not_an_intake_error]
        ).render_hash
      end.to raise_error ArgumentError
    end
  end
end
