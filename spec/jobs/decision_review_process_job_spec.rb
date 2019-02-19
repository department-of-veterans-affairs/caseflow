require "rails_helper"

class AClaimReview
  def update_error!(err)
    @err = err
  end

  def error
    @err
  end

  def id
    123
  end

  def establish!; end
end

describe DecisionReviewProcessJob do
  before do
    allow(Raven).to receive(:extra_context)
  end

  let(:claim_review) { AClaimReview.new }

  let(:vbms_error) do
    VBMS::HTTPError.new("500", "More EPs more problems")
  end

  subject { DecisionReviewProcessJob.perform_now(claim_review) }

  it "saves Exception messages and logs error" do
    capture_raven_log
    allow(claim_review).to receive(:establish!).and_raise(vbms_error)

    subject

    expect(claim_review.error).to eq(vbms_error.to_s)
    expect(@raven_called).to eq(true)
    expect(Raven).to have_received(:extra_context).with(id: 123, class: "AClaimReview")
  end

  it "ignores error on success" do
    allow(claim_review).to receive(:establish!).and_return(true)

    expect(subject).to eq(true)
    expect(claim_review.error).to be_nil
  end

  def capture_raven_log
    allow(Raven).to receive(:capture_exception) { @raven_called = true }
  end
end
