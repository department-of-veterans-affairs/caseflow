require "rails_helper"

describe DecisionRatingIssueSyncJob do
  class NilRatingProfileListError < StandardError; end

  let(:epe) { create(:end_product_establishment, :cleared, established_at: Time.zone.today) }
  let(:request_issue) { create(:request_issue, end_product_establishment: epe) }
  let(:no_ratings_err) { NilRatingProfileListError.new("none!") }
  let(:bgs_transport_err) { BGS::ShareError.new("network!") }

  subject { described_class.perform_now(request_issue) }

  before do
    @raven_called = false
  end

  it "ignores NilRatingProfileListError for Sentry, logs on db" do
    capture_raven_log
    allow(epe).to receive(:sync_decision_issues!).and_raise(no_ratings_err)

    subject

    expect(request_issue.decision_sync_error).to eq("none!")
    expect(@raven_called).to eq(false)
  end

  it "logs BGS errors" do
    capture_raven_log
    allow(epe).to receive(:sync_decision_issues!).and_raise(bgs_transport_err)

    subject

    expect(request_issue.decision_sync_error).to eq("network!")
    expect(@raven_called).to eq(true)
  end

  it "ignores error on success" do
    allow(epe).to receive(:sync_decision_issues!).and_return(true)

    expect(subject).to eq(true)
    expect(request_issue.decision_sync_error).to be_nil
  end

  def capture_raven_log
    allow(Raven).to receive(:capture_exception) { @raven_called = true }
  end
end
