# frozen_string_literal: true

class AClaimReview
  attr_reader :error, :current_user

  def update_error!(err)
    @error = err
  end

  def id
    123
  end

  def establish!
    @current_user = RequestStore[:current_user]
  end

  def sort_by_last_submitted_at; end
end

describe DecisionReviewProcessJob do
  before do
    allow(Raven).to receive(:extra_context)
  end

  let(:establishment_subject) { AClaimReview.new }

  let(:vbms_error) do
    VBMS::HTTPError.new("500", "More EPs more problems")
  end

  subject { DecisionReviewProcessJob.perform_now(establishment_subject) }

  it "saves Exception messages and logs error" do
    capture_raven_log
    allow(establishment_subject).to receive(:establish!).and_raise(vbms_error)

    subject

    expect(establishment_subject.error).to eq(vbms_error.inspect)
    expect(@raven_called).to eq(true)
    expect(Raven).to have_received(:extra_context).with(id: 123, class: "AClaimReview")
  end

  it "ignores error on success" do
    allow(establishment_subject).to receive(:establish!).and_return(true)

    expect(subject).to eq(true)
    expect(establishment_subject.error).to be_nil
  end

  context "transient VBMS error" do
    let(:vbms_error) do
      VBMS::HTTPError.new("500", "FAILED FOR UNKNOWN REASONS")
    end

    it "does not alert Sentry" do
      capture_raven_log
      allow(establishment_subject).to receive(:establish!).and_raise(vbms_error)

      subject

      expect(establishment_subject.error).to eq(vbms_error.inspect)
      expect(@raven_called).to be_falsey
    end
  end

  context "job is retried after 4 hours" do
    it "does not send error to sentry" do
      allow(establishment_subject).to receive(:sort_by_last_submitted_at) { 4.hours.ago }
      allow(establishment_subject).to receive(:establish!).and_raise(vbms_error)
      capture_raven_log

      subject

      expect(@raven_called).to be_falsey
    end
  end

  context ".establishment_user" do
    subject { described_class.new }

    it "sets the user to the system user for establishment" do
      subject.perform(establishment_subject)
      expect(establishment_subject.current_user).to eq(User.system_user)
    end

    context "when the establishment subject is a request issues update" do
      let(:establishment_subject) { create(:request_issues_update) }

      before do
        allow(establishment_subject).to receive(:establish!) { @current_user = RequestStore[:current_user] }
      end

      it "sets the user to the request issue update's user for establishment" do
        subject.perform(establishment_subject)
        expect(@current_user).to eq(establishment_subject.user)
      end
    end
  end

  def capture_raven_log
    allow(Raven).to receive(:capture_exception) { @raven_called = true }
  end
end
