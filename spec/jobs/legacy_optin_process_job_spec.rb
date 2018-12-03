require "rails_helper"

describe LegacyOptinProcessJob do
  let(:legacy_optin) { create(:legacy_issue_optin) }

  let(:an_error) do
    StandardError.new("oops!")
  end

  subject { LegacyOptinProcessJob.perform_now(legacy_optin) }

  it "saves Exception messages and logs error" do
    capture_raven_log
    allow(legacy_optin).to receive(:perform!).and_raise(an_error)

    subject

    expect(legacy_optin.error).to eq(an_error.to_s)
    expect(@raven_called).to eq(true)
  end

  it "ignores error on success" do
    allow(legacy_optin).to receive(:perform!).and_return(true)

    expect(subject).to eq(true)
    expect(legacy_optin.error).to be_nil
  end

  def capture_raven_log
    allow(Raven).to receive(:capture_exception) { @raven_called = true }
  end
end
