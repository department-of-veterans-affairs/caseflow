# frozen_string_literal: true

RSpec.describe Hearings::VaBoxDownloadJob, type: :job do
  let(:hearing) { create(:hearing) }

  let(:file_info) do
    [{
      name: "#{hearing.docket_number}_#{hearing.id}_Hearing.pdf",
      id: "1640086158231",
      created_at: "2024-09-05T061314-0700",
      modified_at: "2024-09-05T061314-0700"
    }]
  end

  subject { described_class.perform_now(file_info) }

  before do
    allow(ExternalApi::VaBoxService).to receive(:new)
      .and_return(Fakes::VaBoxService.new)
  end

  # # see data setup in Fakes::VaBoxService for expectations
  it "call job to download file and upload to S3 and create/update in transciption_table" do
    subject.count == file_info.count
  end

  it "should upload the file to S3 bucket" do
    subject.each do |current_value|
      if current_value.file_type == "pdf"
        expect(current_value.aws_link).to eql("vaec-appeals-caseflow-test/transcript_pdf/#{current_value.file_name}")
      else
        expect(current_value.aws_link).to eql("vaec-appeals-caseflow-test/transcript_text/#{current_value.file_name}")
      end
      expect(current_value.file_status).to eql("Successful upload (AWS)")
    end
  end
end
