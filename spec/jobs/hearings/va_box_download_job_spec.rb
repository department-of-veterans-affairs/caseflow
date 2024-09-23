# frozen_string_literal: true

RSpec.describe Hearings::VaBoxDownloadJob, type: :job do
  describe "#perform" do
    let(:file_info) do
      [{name: "242551_1_LegacyHearing.pdf", id: "1640086158231", created_at: "2024-09-05T061314-0700", modified_at: "2024-09-05T061314-0700"},
      {name: "240903-1_1_Hearing.doc", id: "1640094006674", created_at: "2024-09-05T061308-0700", modified_at: "2024-09-05T061308-0700"}]
    end

    subject { described_class.perform_now(file_info) }

    # # see data setup in Fakes::VaBoxService for expectations
    it "call job to download file and upload to S3 and create/update in transciption_table" do
      expect(subject).to eq(true)
    end
  end
end
