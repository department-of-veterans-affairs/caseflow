# frozen_string_literal: true

describe ExternalApi::VbmsDocumentSeriesForAppeal do
  let(:appeal) { create(:appeal) }

  describe "#fetch" do
    it "successfully calls the service" do
      expect(VBMS::Client).to receive(:from_env_vars).and_return(true)
      expect(ExternalApi::VBMSService).to receive(:send_and_log_request).and_return(true)

      described_class.new(file_number: appeal.veteran_file_number).fetch
    end
  end
end
