# frozen_string_literal: true

describe DecisionIssueSyncJob, :postgres do
  let(:epe) { create(:end_product_establishment, :cleared, established_at: Time.zone.today) }
  let(:request_issue) { create(:request_issue, end_product_establishment: epe) }
  let(:no_ratings_err) { Rating::NilRatingProfileListError.new("none!") }
  let(:bgs_transport_err) { BGS::ShareError.new("network!") }
  let(:sync_lock_err) { Caseflow::Error::SyncLockFailed.new(Time.zone.now.to_s) }

  subject { described_class.perform_now(request_issue) }

  before do
    @raven_called = false
    Timecop.freeze(Time.utc(2023, 1, 1, 12, 0, 0))
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

  it "logs SyncLock errors" do
    capture_raven_log
    allow(request_issue).to receive(:sync_decision_issues!).and_raise(sync_lock_err)
    allow(Rails.logger).to receive(:error)

    subject
    expect(request_issue.decision_sync_error).to eq("#<Caseflow::Error::SyncLockFailed: #{Time.zone.now}>")
    expect(request_issue.decision_sync_attempted_at).to be_within(5.minutes).of 12.hours.ago
    expect(@raven_called).to eq(false)
    expect(Rails.logger).to have_received(:error).with(sync_lock_err)
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
