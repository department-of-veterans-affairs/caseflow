# frozen_string_literal: true

RSpec.describe Hearings::VaBoxDownloadJob, type: :job do
  # open question:

  # 1. How do we handle failed s3 and transcription files?
  # do we just not stop on that error and upate transcription file anyway?
  # also there's no way to delete from s3 using the commons service

  # 2. What is the case for a transcription_file already existing?

  # 3. Account for XLS

  def create_file_info(hearing, file_id, file_type)
    {
      name: "#{hearing.docket_number}_#{hearing.id}_#{hearing.class.name}.#{file_type}",
      id: file_id,
      created_at: "2024-09-05T061314-0700",
      modified_at: "2024-09-05T061314-0700"
    }
  end

  let!(:hearing_1) { create(:hearing) }
  let!(:transcription_1) { create(:transcription, hearing: hearing_1, hearing_type: "Hearing") }

  let(:legacy_hearing_1) { create(:legacy_hearing) }
  let!(:transcription_2) { create(:transcription, hearing: legacy_hearing_1, hearing_type: "LegacyHearing") }

  let!(:hearing_2) { create(:hearing) }
  let!(:hearing_3) { create(:hearing) }
  let!(:transcription_3) { create(:transcription, hearing: hearing_3, hearing_type: "Hearing") }

  let(:file_info) do
    [
      create_file_info(hearing_1, "164008615821", "pdf"),
      create_file_info(legacy_hearing_1, "164008615822", "doc")
    ]
  end

  let(:file_info_zip) do
    [
      create_file_info(hearing_1, "164008615821", "pdf"),
      create_file_info(legacy_hearing_1, "164008615822", "zip")
    ]
  end

  let(:file_info_box_error) do
    [
      create_file_info(hearing_1, "1111111111111", "pdf")
    ]
  end

  let(:file_info_no_hearing) do
    [
      {
        name: "38483_4334_Hearing.pdf",
        id: "164008615821",
        created_at: "2024-09-05T061314-0700",
        modified_at: "2024-09-05T061314-0700"
      }
    ]
  end

  let(:file_info_no_transcript) do
    [
      create_file_info(hearing_2, "164008615821", "pdf")
    ]
  end

  let(:file_info_existing_transcript) do
    [
      create_file_info(hearing_3, "164008615821", "pdf")
    ]
  end

  before do
    allow(ExternalApi::VaBoxService).to receive(:new)
      .and_return(Fakes::VaBoxService.new)
  end

  describe "#perform" do
    it "creates new transcription files with the correct information" do
      described_class.perform_now(file_info)

      transcription_files = TranscriptionFile.all
      expect(transcription_files.count).to eq(2)

      tf = transcription_files[0]
      expect(tf.aws_link).to eq(
        "vaec-appeals-caseflow-test/transcript_pdf/" +
        hearing_1.docket_number + "_" + hearing_1.id.to_s + "_Hearing.pdf"
      )
      expect(tf.docket_number).to eq(hearing_1.docket_number)
      expect(tf.date_returned_box).to eq("2024-09-05 00:00:00.000000000 -0400")
      expect(tf.hearing_type).to eq("Hearing")
      expect(tf.hearing_id).to eq(hearing_1.id)
      expect(tf.file_name).to eq(hearing_1.docket_number + "_" + hearing_1.id.to_s + "_Hearing.pdf")
      expect(tf.file_status).to eq("Successful upload (AWS)")
      expect(tf.file_type).to eq("pdf")
      expect(tf.transcription_id).to eq(transcription_1.id)

      tf = transcription_files[1]
      expect(tf.aws_link).to eq(
        "vaec-appeals-caseflow-test/transcript_text/" +
        legacy_hearing_1.docket_number + "_" + legacy_hearing_1.id.to_s + "_LegacyHearing.doc"
      )
      expect(tf.docket_number).to eq(legacy_hearing_1.docket_number)
      expect(tf.date_returned_box).to eq("2024-09-05 00:00:00.000000000 -0400")
      expect(tf.hearing_type).to eq("LegacyHearing")
      expect(tf.hearing_id).to eq(legacy_hearing_1.id)
      expect(tf.file_name).to eq(legacy_hearing_1.docket_number + "_" + legacy_hearing_1.id.to_s + "_LegacyHearing.doc")
      expect(tf.file_status).to eq("Successful upload (AWS)")
      expect(tf.file_type).to eq("doc")
      expect(tf.transcription_id).to eq(transcription_2.id)
    end

    it "handles valid zip files" do
      allow_any_instance_of(Hearings::VaBoxDownloadJob).to receive(:unzip_file).and_return(
        [
          {
            name: "150000248910004_" + legacy_hearing_1.id.to_s + "_LegacyHearing.pdf",
            created_at: "2024-09-05T061314-0700",
            path: "",
            type: "pdf"
          }
        ]
      )

      described_class.perform_now(file_info_zip)

      transcription_files = TranscriptionFile.all
      expect(transcription_files.count).to eq(2)
    end

    it "handles errors with zip files" do
      expect { described_class.perform_now(file_info_zip) }.to raise_error(
        Hearings::VaBoxDownloadJob::VaBoxDownloadUnzipError
      )
    end

    it "handles errors downloading from box" do
      expect { described_class.perform_now(file_info_box_error) }.to raise_error(
        Hearings::VaBoxDownloadJob::VaBoxDownloadBoxError
      )
    end

    it "handles errors from missing hearing" do
      expect { described_class.perform_now(file_info_no_hearing) }.to raise_error(
        Hearings::VaBoxDownloadJob::VaBoxDownloadHearingError
      )
    end

    it "handles errors from missing transcript" do
      expect { described_class.perform_now(file_info_no_transcript) }.to raise_error(
        Hearings::VaBoxDownloadJob::VaBoxDownloadTranscriptionError
      )
    end

    it "handles errors from s3 upload" do
      # ???
    end

    it "handles updating an existing transcription file" do
      TranscriptionFile.create!(
        hearing_id: hearing_3.id,
        hearing_type: "Hearing",
        docket_number: hearing_3.docket_number,
        file_name: hearing_3.docket_number + "_" + hearing_3.id.to_s + "_Hearing.pdf",
        file_type: "pdf",
        file_status: "",
        transcription_id: transcription_3.id,
        date_upload_aws: Time.zone.now,
        aws_link: "",
        date_returned_box: Time.zone.now
      )

      transcription_files = TranscriptionFile.all
      expect(transcription_files.count).to eq(1)

      described_class.perform_now(file_info_existing_transcript)

      transcription_files = TranscriptionFile.all
      expect(transcription_files.count).to eq(1)

      tf = transcription_files[0]
      expect(tf.aws_link).to eq(
        "vaec-appeals-caseflow-test/transcript_pdf/" +
        hearing_3.docket_number + "_" + hearing_3.id.to_s + "_Hearing.pdf"
      )
      expect(tf.file_status).to eq("Successful upload (AWS)")
    end
  end

  it "calls clean up on temp files when it finishes successfully" do
    file_1 = Rails.root.join(
      "tmp", "file_from_box", "pdf", hearing_1.docket_number + "_" + hearing_1.id.to_s + "_Hearing.pdf"
    )
    file_2 = Rails.root.join(
      "tmp", "file_from_box", "doc",
      legacy_hearing_1.docket_number + "_" + legacy_hearing_1.id.to_s + "_LegacyHearing.doc"
    )

    described_class.perform_now(file_info)

    expect(File.exist?(file_1)).to be_falsy
    expect(File.exist?(file_2)).to be_falsy
  end

  it "calls cleanup on exception" do
    file_1 = Rails.root.join(
      "tmp", "file_from_box", "pdf", hearing_1.docket_number + "_" + hearing_1.id.to_s + "_Hearing.pdf"
    )
    file_2 = Rails.root.join(
      "tmp", "file_from_box", "zip",
      legacy_hearing_1.docket_number + "_" + legacy_hearing_1.id.to_s + "_LegacyHearing.zip"
    )

    expect { described_class.perform_now(file_info_zip) }.to raise_error(
      Hearings::VaBoxDownloadJob::VaBoxDownloadUnzipError
    )

    expect(File.exist?(file_1)).to be_falsy
    expect(File.exist?(file_2)).to be_falsy
  end
end
