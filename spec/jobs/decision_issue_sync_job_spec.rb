# frozen_string_literal: true

describe DecisionIssueSyncJob, :postgres do
  let(:epe) { create(:end_product_establishment, :cleared, established_at: Time.zone.today) }
  let(:request_issue) { create(:request_issue, end_product_establishment: epe) }
  let(:no_ratings_err) { Rating::NilRatingProfileListError.new("none!") }
  let(:bgs_transport_err) { BGS::ShareError.new("network!") }

  subject { described_class.perform_now(request_issue) }

  before do
    @raven_called = false
  end

  it "ignores NilRatingProfileListError for Sentry, logs on db" do
    capture_raven_log
    allow(request_issue).to receive(:sync_decision_issues!).and_raise(no_ratings_err)

    subject

    expect(request_issue.decision_sync_error).to eq("#<Rating::NilRatingProfileListError: none!>")
    expect(@raven_called).to eq(false)
  end

  it "logs BGS errors" do
    capture_raven_log
    allow(request_issue).to receive(:sync_decision_issues!).and_raise(bgs_transport_err)

    subject

    expect(request_issue.decision_sync_error).to eq("#<BGS::ShareError: network!>")
    expect(@raven_called).to eq(true)
  end

  it "logs other errors" do
    capture_raven_log
    allow(request_issue).to receive(:sync_decision_issues!).and_raise(StandardError.new("random error"))

    subject

    expect(request_issue.decision_sync_error).to eq("#<StandardError: random error>")
    expect(@raven_called).to eq(true)
  end

  it "ignores error on success" do
    allow(request_issue).to receive(:sync_decision_issues!).and_return(true)

    expect(subject).to eq(true)
    expect(request_issue.decision_sync_error).to be_nil
  end

  def capture_raven_log
    allow(Raven).to receive(:capture_exception) { @raven_called = true }
  end
end
