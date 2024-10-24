# frozen_string_literal: true

RSpec.describe Hearings::VaBoxDownloadJob, type: :job do
  let(:hearing) { create(:hearing) }
  let(:ama_file_id) { "164008615821" }

  let(:legacy_hearing) { create(:legacy_hearing) }
  let(:legacy_file_id) { "1640086158232" }

  def create_file_info(hearing, file_id)
    {
      name: "#{hearing.docket_number}_#{hearing.id}_#{hearing.class.name}.pdf",
      id: file_id,
      created_at: "2024-09-05T061314-0700",
      modified_at: "2024-09-05T061314-0700"
    }
  end

  let(:file_info) do
    [
      create_file_info(hearing, ama_file_id)

      # TODO: Uncomment after APPEALS-59937 has been completed
      # create_file_info(legacy_hearing, legacy_file_id)
    ]
  end

  subject { described_class.perform_now(file_info) }

  before do
    allow(ExternalApi::VaBoxService).to receive(:new)
      .and_return(Fakes::VaBoxService.new)

    Transcription.create(hearing_id: hearing.id)

  end

  # # see data setup in Fakes::VaBoxService for expectations
  it "call job to download file and upload to S3 and create/update in transciption_table" do
    expect(Hearings::TranscriptionFile.count).to eq 0

    subject

    expect(Hearings::TranscriptionFile.count).to eq file_info.count
    expect(hearing.transcription_files.count).to eq 1

    # TODO: Add similar tests for the legacy hearing
    ama_file_created = hearing.transcription_files.first
    expect(ama_file_created.file_type).to eq "pdf"
    expect(ama_file_created.docket_number).to eq hearing.docket_number
  end

  # TODO: Add test cases for when a zip file is passed in
end
