# frozen_string_literal: true

RSpec.describe Hearings::VaBoxDownloadJob, type: :job do
  # open question:

  # 3. Account for XLS, make sure it has a package

  # 4. Held hearings

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

  let!(:transcription_package_1) { create(:transcription_package, task_number: "BVA2024001") }

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

  let(:file_info_xls_good) do
    [
      {
        name: "Completed BVA2024001.xls",
        id: "164008615821",
        created_at: "2024-09-05T061314-0700",
        modified_at: "2024-09-05T061314-0700"
      }
    ]
  end

  let(:file_info_xls_bad) do
    [
      {
        name: "Completed BVA2024002.xls",
        id: "164008615821",
        created_at: "2024-09-05T061314-0700",
        modified_at: "2024-09-05T061314-0700"
      }
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
      # write mock file from pretend zip
      tmp_unzip_file_name = "150000248910004_" + legacy_hearing_1.id.to_s + "_LegacyHearing.pdf"
      tmp_folder = Rails.root.join("tmp", "file_from_box", "pdf")
      tmp_unzip_file_path = Rails.root.join("tmp", "file_from_box", "pdf", tmp_unzip_file_name)
      tmp_zip_file_path = Rails.root.join("tmp", "mock_file.zip")

      FileUtils.mkdir_p(tmp_folder) unless File.directory?(tmp_folder)
      File.open(tmp_unzip_file_path.to_s, "w") { |f| f.write "test" }

      File.delete(tmp_zip_file_path) if File.exist?(tmp_zip_file_path)
      Zip::File.open(tmp_zip_file_path, create: true) do |zip_file|
        zip_file.add(File.basename(tmp_unzip_file_path), tmp_unzip_file_path)
      end

      mock_file = Zip::File.open(tmp_zip_file_path)
      allow(Zip::File).to receive(:open) { |&block| block.call(mock_file) }

      described_class.perform_now(file_info_zip)

      transcription_files = TranscriptionFile.all
      expect(transcription_files.count).to eq(2)

      File.delete(tmp_zip_file_path) if File.exist?(tmp_zip_file_path)
    end

    it "handles errors with zip files" do
      expect { described_class.perform_now(file_info_zip) }.to raise_error(
        Hearings::VaBoxDownloadJob::VaBoxDownloadUnzipError
      )
    end

    it "handles valid xls files" do
      described_class.perform_now(file_info_xls_good)
      transcription_files = TranscriptionFile.all
      expect(transcription_files.count).to eq(1)

      tf = transcription_files[0]
      expect(tf.file_name).to eq("Completed BVA2024001.xls")
      expect(tf.docket_number).to be_nil
      expect(tf.hearing_type).to be_nil
      expect(tf.hearing_id).to be_nil
      expect(tf.file_status).to eq("Successful upload (AWS)")
      expect(tf.file_type).to eq("xls")
      expect(tf.transcription_id).to be_nil
    end

    it "handles errors when xls files are missing packages" do
      expect { described_class.perform_now(file_info_xls_bad) }.to raise_error(
        Hearings::VaBoxDownloadJob::VaBoxDownloadTranscriptionPackageError
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

    it "handles s3 errors by setting failed status" do
      expect(S3Service).to receive(:store_file).exactly(2).times.and_raise(StandardError)

      described_class.perform_now(file_info)

      transcription_files = TranscriptionFile.all
      expect(transcription_files.count).to eq(2)
      expect(transcription_files[0].file_status).to eq("Failed upload (AWS)")
      expect(transcription_files[1].file_status).to eq("Failed upload (AWS)")
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
end
