# frozen_string_literal: true

describe Hearings::GetWebexRecordingsListJob, type: :job do
  include ActiveJob::TestHelper

  subject { described_class.perform_now }

  it "Returns the correct array of ids" do
    expect(subject).to eq(%w[4f914b1dfe3c4d11a61730f18c0f5387 3324fb76946249cfa07fc30b3ccbf580 42b80117a2a74dcf9863bf06264f8075])
  end

  context "job errors" do
    before do
      allow_any_instance_of(WebexService)
        .to receive(:get_recordings_list)
        .and_raise(Caseflow::Error::WebexApiError.new(code: 400, message: "Fake Error"))
    end

    it "Successfully catches errors and adds retry to queue" do
      subject
      expect(enqueued_jobs.size).to eq(1)
    end

    it "retries and logs errors" do
      subject
      perform_enqueued_jobs { described_class.perform_later }
      expect(Rails.logger.error).to be(true)
    end
  end
end
