# frozen_string_literal: true

describe Hearings::DownloadTranscriptionFileJob do
  include ActiveJob::TestHelper

  describe "#perform" do
    let(:link) { "https://picsum.photos/200" }
    let(:hearing) { create(:hearing) }
    let(:docket_number) { hearing.docket_number }
    let(:appeal_id) { hearing.appeal.uuid }
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
        allow_any_instance_of(TranscriptionFile).to receive(:clean_up_tmp_location).and_return(nil)
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

    shared_context "failed download from Webex" do
      let(:link) { "https://picsum.photos/broken" }
      let(:download_error) { Hearings::DownloadTranscriptionFileJob::FileDownloadError }
      let(:file_status) { Constants.TRANSCRIPTION_FILE_STATUSES.retrieval.failure }

      it "raises error and creates TranscriptionFileRecord" do
        expect { subject }.to raise_error(download_error)
          .and change(TranscriptionFile, :count).by(1)
      end

      it "updates file_status of TranscriptionFile record, leaves date_receipt_recording nil" do
        expect { subject }.to raise_error(download_error)
        expect(transcription_file.date_receipt_recording).to be_nil
        expect(transcription_file.file_status).to eq(file_status)
      end

      it "doesn't queue upload to AWS" do
        expect { subject }.to raise_error(download_error)
        expect(transcription_file).to_not receive(:upload_to_s3!)
        expect(transcription_file.date_upload_aws).to be_nil
      end
    end

    %w[mp4 mp3].each do |file_type|
      context "#{file_type} file" do
        let(:file_type) { file_type }

        context "successful download from Webex and upload to S3" do
          let(:file_status) { Constants.TRANSCRIPTION_FILE_STATUSES.upload.success }

          it "creates new TranscriptionFile record" do
            expect { subject }.to change(TranscriptionFile, :count).by(1)
            expect(transcription_file.file_type).to eq(file_type)
          end

          it "updates date_receipt_recording of TranscriptionFile record" do
            subject
            expect(transcription_file.date_receipt_recording).to_not be_nil
          end

          include_examples "all file types"
        end

        context "failed download from Webex" do
          include_context "failed download from Webex"
        end
      end
    end

    shared_context "converted file" do
      let(:transcription_file) { converted_transcription_file }
      let(:file_status) { Constants.TRANSCRIPTION_FILE_STATUSES.upload.success }
      let(:s3_location) { converted_s3_location }

      include_examples "all file types"
    end

    context "vtt file" do
      let(:file_type) { "vtt" }
      let(:file_status) { Constants.TRANSCRIPTION_FILE_STATUSES.conversion.success }
      let(:conversion_type) { "rtf" }
      let(:converted_file_name) { file_name.gsub(file_type, conversion_type) }
      let(:converted_tmp_location) { tmp_location.gsub(file_type, conversion_type) }
      let(:converted_transcription_file) { TranscriptionFile.find_by(file_name: converted_file_name) }
      let(:converted_s3_location) { "#{folder_name}/#{s3_sub_folders[conversion_type.to_sym]}/#{converted_file_name}" }

      context "successful download from Webex, upload to S3, and conversion to rtf" do
        before do
          File.open(converted_tmp_location, "w")
          allow_any_instance_of(TranscriptionTransformer).to receive(:call).and_return([converted_tmp_location])
        end

        after { File.delete(converted_tmp_location) if File.exist?(converted_tmp_location) }

        it "creates two new TranscriptionFile records" do
          expect { subject }.to change(TranscriptionFile, :count).by(2)
          expect(transcription_file.file_type).to eq(file_type)
          expect(converted_transcription_file.file_type).to eq(conversion_type)
        end

        it "updates date_receipt_recording of TranscriptionFile record" do
          subject
          expect(transcription_file.date_receipt_recording).to_not be_nil
        end

        include_examples "all file types"

        context "rtf file" do
          include_context "converted file"
        end
      end

      context "failed download from Webex" do
        include_context "failed download from Webex"
      end

      context "inaudibles present in vtt" do
        let(:rtf_tmp_location) { tmp_location.gsub(file_type, "rtf") }
        let(:csv_tmp_location) { tmp_location.gsub(file_type, "csv") }

        before do
          File.open(rtf_tmp_location, "w")
          File.open(csv_tmp_location, "w")
          allow_any_instance_of(TranscriptionTransformer).to receive(:call)
            .and_return([rtf_tmp_location, csv_tmp_location])
        end

        after do
          File.delete(rtf_tmp_location) if File.exist?(rtf_tmp_location)
          File.delete(csv_tmp_location) if File.exist?(csv_tmp_location)
        end

        it "creates three new TranscriptionFile records" do
          expect { subject }.to change(TranscriptionFile, :count).by(3)
          expect(transcription_file.file_type).to eq(file_type)
          expect(converted_transcription_file.file_type).to eq(conversion_type)
        end

        it "updates date_receipt_recording of TranscriptionFile record" do
          subject
          expect(transcription_file.date_receipt_recording).to_not be_nil
        end

        include_examples "all file types"

        %w[rtf csv].each do |conversion_type|
          context "#{conversion_type} file" do
            let(:conversion_type) { conversion_type }

            include_context "converted file"
          end
        end
      end

      context "failed conversion" do
        let(:file_status) { Constants.TRANSCRIPTION_FILE_STATUSES.conversion.failure }
        let(:conversion_error) { TranscriptionTransformer::FileConversionError }

        before do
          allow_any_instance_of(TranscriptionTransformer).to receive(:call)
            .and_raise(conversion_error)
        end

        it "raises error and creates TranscriptionFileRecord" do
          expect { subject }.to raise_error(conversion_error).and change(TranscriptionFile, :count).by(1)
          expect(transcription_file.file_type).to eq(file_type)
        end

        it "saves downloaded file to correct tmp sub-directory" do
          expect { subject }.to raise_error(conversion_error)
          allow_any_instance_of(TranscriptionFile).to receive(:clean_up_tmp_location).and_return(nil)
          expect(File.exist?(tmp_location)).to be true
        end

        it "updates date_upload_aws of TranscriptionFile record" do
          expect { subject }.to raise_error(conversion_error)
          expect(transcription_file.date_upload_aws).to_not be_nil
        end

        it "uploads file to correct S3 location" do
          expect { subject }.to raise_error(conversion_error)
          expect(transcription_file.aws_link).to eq(s3_location)
        end

        it "updates file_status of TranscriptionFile record" do
          expect { subject }.to raise_error(conversion_error)
          expect(transcription_file.file_status).to eq(file_status)
        end
      end

      context "job retries" do
        let(:file_type) { "vtt" }
        let(:upload_error) { TranscriptionFileUpload::FileUploadError }
        let(:download_error) { Hearings::DownloadTranscriptionFileJob::FileDownloadError }
        let(:conversion_error) { TranscriptionTransformer::FileConversionError }
        let(:file_name_error) { Hearings::DownloadTranscriptionFileJob::FileNameError }

        before do
          allow_any_instance_of(TranscriptionFile).to receive(:clean_up_tmp_location).and_return(nil)
        end

        shared_examples "sends email template" do
          context "email delivery succeeds" do
            it "mailer receives correct params" do
              allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).and_call_original
              expect(TranscriptionFileIssuesMailer).to receive(:issue_notification).with(error_details)
              expect_any_instance_of(described_class).to receive(:log_error).once
              perform_enqueued_jobs { described_class.perform_later(download_link: link, file_name: file_name) }
            end
          end

          context "email delivery fails" do
            it "captures external delivery error" do
              allow(TranscriptionFileIssuesMailer).to receive(:issue_notification).with(error_details)
                .and_raise(GovDelivery::TMS::Request::Error.new(500))
              expect_any_instance_of(described_class).to receive(:log_error).twice
              perform_enqueued_jobs { described_class.perform_later(download_link: link, file_name: file_name) }
            end
          end
        end

        context "failed upload" do
          let(:error_details) do
            {
              error: { type: "upload", explanation: "upload a #{file_type} file to S3" },
              provider: "S3",
              docket_number: docket_number,
              appeal_id: appeal_id
            }
          end

          before do
            allow_any_instance_of(TranscriptionFile).to receive(:upload_to_s3!)
              .and_raise(upload_error)
          end

          include_examples "sends email template"
        end

        context "failed download" do
          let(:error_details) do
            {
              error: { type: "download", explanation: "download a #{file_type} file from Webex" },
              provider: "webex",
              temporary_download_link: { link: link },
              docket_number: docket_number,
              appeal_id: appeal_id
            }
          end

          before do
            allow_any_instance_of(Hearings::DownloadTranscriptionFileJob).to receive(:download_file_to_tmp!)
              .and_raise(download_error)
          end

          include_examples "sends email template"
        end

        context "failed conversion" do
          let(:error_details) do
            {
              error: { type: "conversion", explanation: "convert a #{file_type} file to #{conversion_type}" },
              docket_number: docket_number,
              appeal_id: appeal_id
            }
          end

          before do
            allow_any_instance_of(Hearings::DownloadTranscriptionFileJob).to receive(:convert_to_rtf_and_upload_to_s3!)
              .and_raise(conversion_error)
          end

          include_examples "sends email template"
        end

        context "failed to parse filename" do
          let(:appeal_id) { nil }
          let(:error_details) do
            {
              error: { type: "download", explanation: "download a file from Webex" },
              provider: "webex",
              reason: "Unable to parse hearing information from file name: #{file_name}",
              expected_file_name_format: "[docket_number]_[internal_id]_[hearing_type].[file_type]",
              docket_number: nil,
              appeal_id: nil
            }
          end

          before do
            allow_any_instance_of(Hearings::DownloadTranscriptionFileJob).to receive(:parse_hearing)
              .and_raise(file_name_error)
          end

          include_examples "sends email template"
        end
      end

      context "job redownloads and reconverts" do
        let(:file_type) { "vtt" }
        let!(:upload_date) { 1.day.ago }
        let!(:converted_date) { 1.day.ago }
        let!(:transcription_file) do
          TranscriptionFile.find_or_create_by!(
            hearing_id: hearing.id,
            hearing_type: hearing.class.to_s,
            file_name: file_name,
            file_type: file_type,
            docket_number: hearing.docket_number,
            file_status: "Successful upload (AWS)",
            date_upload_aws: upload_date,
            date_converted: converted_date,
            aws_link: "www.test.com"
          )
        end

        it "does not redownload non vtt files if already exists in aws" do
          transcription_file.update!(file_type: "mp3")
          subject
          expect(File.exist?(tmp_location)).to eq(false)
        end

        it "does not redownload vtt files if already converted" do
          transcription_file.update!(file_status: "Successful conversion")
          subject
          expect(File.exist?(tmp_location)).to eq(false)
        end

        it "does not reupload if file was already uploaded" do
          transcription_file.update!(date_upload_aws: upload_date)
          subject
          expect(transcription_file.date_upload_aws).to eq(upload_date)
        end

        it "does not reconvert if vtt has already converted file to rtf" do
          transcription_file.update!(date_converted: converted_date)
          subject
          expect(transcription_file.date_converted).to eq(converted_date)
        end
      end
    end
  end
end
