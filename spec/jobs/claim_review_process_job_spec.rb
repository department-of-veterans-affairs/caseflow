require "rails_helper"

class AClaimReview
  def update_error!(err)
    @err = err
  end

  def error
    @err
  end

  def process_end_product_establishments!; end
end

describe ClaimReviewProcessJob do
  let(:claim_review) { AClaimReview.new }

  let(:vbms_error) do
    VBMS::HTTPError.new("500", "More EPs more problems")
  end

  subject { ClaimReviewProcessJob.perform_now(claim_review) }

  it "saves Exception messages and re-throws error" do
    allow(claim_review).to receive(:process_end_product_establishments!).and_raise(vbms_error)

    expect { subject }.to raise_error(vbms_error)
    expect(claim_review.error).to eq(vbms_error.to_s)
  end

  it "ignores error on success" do
    allow(claim_review).to receive(:process_end_product_establishments!).and_return(true)

    expect(subject).to eq(true)
    expect(claim_review.error).to be_nil
  end
end
