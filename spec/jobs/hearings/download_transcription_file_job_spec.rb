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
    let(:s3_location) { "#{folder_name}/#{s3_sub_folders[file_type.to_sym]}/#{file_name}" }

    subject { described_class.new.perform(download_link: link, file_name: file_name) }

    after { File.delete(tmp_location) if File.exist?(tmp_location) }

    shared_examples "all file types" do
      it "saves downloaded file to correct tmp sub-directory" do
        allow_any_instance_of(TranscriptionFile).to receive(:clean_up_tmp_location).and_return("hi")
        subject
        expect(File.exist?(tmp_location)).to be true
      end

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
        expect(transcription_file.file_status).to eq(Constants.TRANSCRIPTION_FILE_STATUSES.retrieval.failure)
      end

      it "doesn't queue upload to AWS" do
        expect { subject }.to raise_error(Hearings::DownloadTranscriptionFileJob::FileDownloadError)
        expect(transcription_file).to_not receive(:upload_to_s3!)
        expect(transcription_file.date_upload_aws).to be_nil
      end
    end

    %w[mp4 mp3].each do |file_type|
      context "#{file_type} file" do
        let(:file_type) { file_type }
        let(:file_status) { Constants.TRANSCRIPTION_FILE_STATUSES.upload.success }

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
      end
    end

    shared_context "convertible file" do
      let(:converted_file_name) { file_name.gsub(file_type, conversion_type) }
      let(:converted_tmp_location) { tmp_location.gsub(file_type, conversion_type) }
      let(:converted_transcription_file) { TranscriptionFile.find_by(file_name: converted_file_name) }
      let(:converted_s3_location) { "#{folder_name}/#{s3_sub_folders[conversion_type.to_sym]}/#{converted_file_name}" }

      after { File.delete(converted_tmp_location) if File.exist?(converted_tmp_location) }

      it "creates two new TranscriptionFile records" do
        expect { subject }.to change(TranscriptionFile, :count).by(2)
        expect(transcription_file.file_type).to eq(file_type)
        expect(converted_transcription_file.file_type).to eq(conversion_type)
      end

      it "updates date_receipt_webex of TranscriptionFile record" do
        subject
        expect(transcription_file.date_receipt_webex).to_not be_nil
      end

      include_examples "all file types"
    end

    shared_context "converted file" do
      let(:transcription_file) { converted_transcription_file }
      let(:file_status) { Constants.TRANSCRIPTION_FILE_STATUSES.upload.success }
      let(:s3_location) { converted_s3_location }

      include_examples "all file types"
    end

    context "vtt file" do
      let(:file_type) { "vtt" }
      let(:conversion_type) { "rtf" }
      let(:file_status) { Constants.TRANSCRIPTION_FILE_STATUSES.conversion.success }

      context "successful download from Webex, upload to S3, and conversion to rtf" do
        before do
          File.open(converted_tmp_location, "w")
          allow_any_instance_of(TranscriptionTransformer).to receive(:call).and_return(converted_tmp_location)
        end

        include_context "convertible file"

        context "rtf file" do
          include_context "converted file"
        end
      end

      context "failed download from Webex" do
        let(:link) { "https://picsum.photos/broken" }

        include_examples "failed download from Webex"
      end

      context "failed conversion to rtf" do
        let(:conversion_type) { "csv" }
        let(:file_status) { Constants.TRANSCRIPTION_FILE_STATUSES.conversion.failure }

        subject do
          perform_enqueued_jobs { described_class.perform_later(download_link: link, file_name: file_name) }
        end

        before do
          allow_any_instance_of(TranscriptionTransformer).to receive(:call)
            .and_raise(TranscriptionTransformer::FileConversionError)
        end

        include_context "convertible file"

        it "does not update date_converted of TranscriptionFile record" do
          subject
          expect(transcription_file.date_converted).to be_nil
        end

        include_examples "all file types"

        context "csv file" do
          include_context "converted file"
        end
      end
    end
  end
end
