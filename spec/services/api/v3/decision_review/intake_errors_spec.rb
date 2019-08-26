# frozen_string_literal: true

require "rails_helper"

context Api::V3::DecisionReview::IntakeErrors do
  context ".render_hash" do
    let(:a) { Api::V3::DecisionReview::IntakeError.new(:intake_start_failed) }
    let(:b) { Api::V3::DecisionReview::IntakeError.new(:veteran_not_accessible) }
    subject { Api::V3::DecisionReview::IntakeErrors.new([a, b]) }
    it "should return a properly formatted render hash with a correct status (the highest one)" do
      expect(subject.render_hash).to eq(json: { errors: [a, b] }, status: [a.status, b.status].max)
    end
  end
end
