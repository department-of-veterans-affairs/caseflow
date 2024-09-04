# frozen_string_literal: true

describe RetryDecisionReviewProcessJob do
  subject { described_class.new }
  let!(:supplemental_claims) { create_list(:supplemental_claim, 3, establishment_error: "SomeError") }

  it_behaves_like "a Master Scheduler serializable object", RetryDecisionReviewProcessJob

  it "clears errors" do
    expect(subject.records_with_errors.count).to eq(3)
    subject.perform

    expect(supplemental_claims.first.reload.establishment_error).to be_nil
    expect(subject.records_with_errors.count).to eq(0)
  end
end
