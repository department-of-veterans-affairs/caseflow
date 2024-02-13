# frozen_string_literal: true

describe Hearings::DownloadTranscriptionFileJob do
  include ActiveJob::TestHelper

  describe "#perform" do
    let(:link) { "https://picsum.photos/200" }
    let(:hearing) { create(:hearing) }
    let(:docket_number) { hearing.docket_number }
    let(:file_name) { "#{docket_number}_#{hearing.id}_#{hearing.class}.#{file_type}" }
    let(:tmp_location) { File.join(Rails.root, "tmp", "transcription_files", file_type, file_name) }
    let(:transcription_file) { TranscriptionFile.find_by(file_name: file_name) }
    let(:s3_sub_bucket) { "vaec-appeals-caseflow" }
    let(:folder_name) { (Rails.deploy_env == :prod) ? s3_sub_bucket : "#{s3_sub_bucket}-#{Rails.deploy_env}" }
    let(:s3_sub_folders) do
      {
        mp3: "transcript_audio",
        mp4: "transcript_audio",
        vtt: "transcript_raw",
        rtf: "transcript_text",
        xls: "transcript_text",
        csv: "transcript_text"
      }
    end
    let(:s3_location) { folder_name + "/" + s3_sub_folders[file_type.to_sym] + "/" + file_name }

    subject { described_class.new.perform(download_link: link, file_name: file_name) }

    before { TranscriptionFile }

    after { File.delete(tmp_location) if File.exist?(tmp_location) }

    shared_examples "all file types" do
      it "updates date_upload_aws of TranscriptionFile record" do
        subject
        expect(transcription_file.date_upload_aws).to_not be_nil
      end

      it "uploads file to correct S3 location" do
        subject
        expect(transcription_file.aws_link).to eq(s3_location)
      end

      it "updates file_status of TranscriptionFile record" do
        subject
        expect(transcription_file.file_status).to eq(file_status)
      end
    end

    shared_examples "failed download from Webex" do
      it "raises error and creates TranscriptionFileRecord" do
        expect { subject }.to raise_error(Hearings::DownloadTranscriptionFileJob::FileDownloadError)
          .and change(TranscriptionFile, :count).by(1)
      end

      it "updates file_status of TranscriptionFile record, leaves date_receipt_webex nil" do
        expect { subject }.to raise_error(Hearings::DownloadTranscriptionFileJob::FileDownloadError)
        expect(transcription_file.date_receipt_webex).to be_nil
        expect(transcription_file.file_status).to eq(TranscriptionFile::FILE_STATUSES[:retrieval][:failure])
      end

      it "doesn't queue upload to AWS" do
        expect { subject }.to raise_error(Hearings::DownloadTranscriptionFileJob::FileDownloadError)
        expect(transcription_file).to_not receive(:upload_to_s3!)
        expect(transcription_file.date_upload_aws).to be_nil
      end
    end

    context "mp3 file" do
      let(:file_type) { "mp3" }
      let(:file_status) { TranscriptionFile::FILE_STATUSES[:upload][:success] }

      context "successful download from Webex and upload to S3" do
        it "creates new TranscriptionFile record" do
          expect { subject }.to change(TranscriptionFile, :count).by(1)
          expect(transcription_file.file_type).to eq(file_type)
        end

        it "updates date_receipt_webex of TranscriptionFile record" do
          subject
          expect(transcription_file.date_receipt_webex).to_not be_nil
        end

        include_examples "all file types"
      end

      context "conversion request unnecessarily supplied to job" do
        let(:download_job) { described_class.new }

        it "ignores conversion request and successfully uploads mp3 to S3" do
          expect(download_job).to_not receive(:convert_file)
          download_job.perform(download_link: link, file_name: file_name, conversion_needed: true)
          expect(transcription_file.file_status).to eq(file_status)
          expect(transcription_file.date_converted).to be_nil
        end
      end

      context "failed download from Webex" do
        let(:link) { "https://picsum.photos/broken" }

        include_examples "failed download from Webex"
      end
    end

    context "mp4 file" do
      let(:file_type) { "mp4" }
      let(:file_status) { TranscriptionFile::FILE_STATUSES[:upload][:success] }

      context "successful download from Webex and upload to S3" do
        it "creates new TranscriptionFile record" do
          expect { subject }.to change(TranscriptionFile, :count).by(1)
          expect(transcription_file.file_type).to eq(file_type)
        end

        it "updates date_receipt_webex of TranscriptionFile record" do
          subject
          expect(transcription_file.date_receipt_webex).to_not be_nil
        end

        include_examples "all file types"
      end

      context "failed download from Webex" do
        let(:link) { "https://picsum.photos/broken" }

        include_examples "failed download from Webex"
      end

      context "succesful conversion to mp3 if necessary" do
        subject { described_class.new.perform(download_link: link, file_name: file_name, conversion_needed: true) }

        let(:file_type) { "mp4" }
        let(:file_status) { TranscriptionFile::FILE_STATUSES[:conversion][:success] }
        let(:mp3_file_name) { file_name.gsub("mp4", "mp3") }
        let(:mp3_tmp_location) { tmp_location.gsub("mp4", "mp3") }
        let(:mp3_transcription_file) { TranscriptionFile.find_by(file_name: mp3_file_name) }
        let(:mp3_s3_location) { folder_name + "/transcript_audio/" + mp3_file_name }

        before do
          File.open(mp3_tmp_location, "w")
          allow_any_instance_of(VideoToAudioFileConverter).to receive(:call).and_return(mp3_tmp_location)
        end

        after { File.delete(mp3_tmp_location) if File.exist?(mp3_tmp_location) }

        it "creates two new TranscriptionFile records, one for mp4 and one for mp3" do
          expect { subject }.to change(TranscriptionFile, :count).by(2)
          expect(transcription_file.file_type).to eq("mp4")
          expect(mp3_transcription_file.file_type).to eq("mp3")
        end

        it "updates date_receipt_webex of TranscriptionFile record" do
          subject
          expect(transcription_file.date_receipt_webex).to_not be_nil
        end

        include_examples "all file types"

        context "mp3 file" do
          let(:transcription_file) { mp3_transcription_file }
          let(:file_status) { TranscriptionFile::FILE_STATUSES[:upload][:success] }
          let(:s3_location) { mp3_s3_location }

          include_examples "all file types"
        end
      end
    end

    context "vtt file" do
      let(:file_type) { "vtt" }

      context "successful download from Webex, upload to S3, and conversion to rtf" do
        let(:file_status) { TranscriptionFile::FILE_STATUSES[:conversion][:success] }
        let(:rtf_file_name) { file_name.gsub("vtt", "rtf") }
        let(:rtf_tmp_location) { tmp_location.gsub("vtt", "rtf") }
        let(:rtf_transcription_file) { TranscriptionFile.find_by(file_name: rtf_file_name) }
        let(:rtf_s3_location) { folder_name + "/transcript_text/" + rtf_file_name }

        before do
          File.open(rtf_tmp_location, "w")
          allow_any_instance_of(TranscriptionTransformer).to receive(:call).and_return(rtf_tmp_location)
        end

        after { File.delete(rtf_tmp_location) if File.exist?(rtf_tmp_location) }

        it "creates two new TranscriptionFile records, one for vtt and one for rtf" do
          expect { subject }.to change(TranscriptionFile, :count).by(2)
          expect(transcription_file.file_type).to eq("vtt")
          expect(rtf_transcription_file.file_type).to eq("rtf")
        end

        it "updates date_receipt_webex of TranscriptionFile record" do
          subject
          expect(transcription_file.date_receipt_webex).to_not be_nil
        end

        include_examples "all file types"

        context "rtf file" do
          let(:transcription_file) { rtf_transcription_file }
          let(:file_status) { TranscriptionFile::FILE_STATUSES[:upload][:success] }
          let(:s3_location) { rtf_s3_location }

          include_examples "all file types"
        end
      end

      context "failed download from Webex" do
        let(:link) { "https://picsum.photos/broken" }

        include_examples "failed download from Webex"
      end

      context "failed conversion of vtt to rtf" do
        let(:file_status) { TranscriptionFile::FILE_STATUSES[:conversion][:failure] }
        let(:csv_file_name) { file_name.gsub("vtt", "csv") }
        let(:csv_tmp_location) { tmp_location.gsub("vtt", "csv") }
        let(:csv_transcription_file) { TranscriptionFile.find_by(file_name: csv_file_name) }
        let(:csv_s3_location) { folder_name + "/transcript_text/" + csv_file_name }

        subject do
          perform_enqueued_jobs { described_class.perform_later(download_link: link, file_name: file_name) }
        end

        before do
          allow_any_instance_of(TranscriptionTransformer).to receive(:call)
            .and_raise(Caseflow::Error::FileConversionError)
        end

        it "creates two new TranscriptionFile records, one for vtt and one for csv" do
          expect { subject }.to change(TranscriptionFile, :count).by(2)
          expect(transcription_file.file_type).to eq("vtt")
          expect(csv_transcription_file.file_type).to eq("csv")
        end

        it "updates date_receipt_webex of TranscriptionFile record" do
          subject
          expect(transcription_file.date_receipt_webex).to_not be_nil
        end

        it "does not update date_converted of TranscriptionFile record" do
          subject
          expect(transcription_file.date_converted).to be_nil
        end

        include_examples "all file types"

        context "csv file" do
          let(:transcription_file) { csv_transcription_file }
          let(:file_status) { TranscriptionFile::FILE_STATUSES[:upload][:success] }
          let(:s3_location) { csv_s3_location }

          include_examples "all file types"
        end
      end
    end
  end
end
