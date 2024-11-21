# frozen_string_literal: true

RSpec.describe Hearings::VaBoxUploadJob do
  include ActiveJob::TestHelper

  let(:box_service) { Fakes::VaBoxService.new }
  let!(:hearing) { create(:hearing) }
  let!(:legacy_hearing) { create(:legacy_hearing) }
  let(:transcription_package) do
    create(
      :transcription_package,
      date_upload_box: nil,
      status: "Successful Upload (AWS)"
    )
  end
  let(:master_zip_file_path) { Rails.root.join("tmp", "transcription_files", "BVAaa-1111-0001.zip") }
  subject { described_class.perform_now(transcription_package) }

  before do
    User.authenticate!(user: create(:user))
    allow(ExternalApi::VaBoxService).to receive(:new).and_return(box_service)
    allow(box_service).to receive(:get_child_folder_id).and_return("0000001")
    allow(Caseflow::S3Service).to receive(:fetch_file).and_return(master_zip_file_path)
    TranscriptionPackageHearing.create!(
      hearing_id: hearing.id,
      transcription_package_id: transcription_package.id
    )
    TranscriptionPackageLegacyHearing.create!(
      legacy_hearing_id: legacy_hearing.id,
      transcription_package_id: transcription_package.id
    )
    [hearing, legacy_hearing].each do |hearing|
      t = create(:transcription, hearing_id: hearing.id, task_number: transcription_package.task_number)
      %w[vtt mp3 zip rtf].each do |ext|
        create(
          :transcription_file,
          hearing: hearing,
          file_type: ext,
          file_name: "test.#{ext}",
          transcription: t
        )
      end
    end
  end

  describe "#perform" do
    context "happy path" do
      it "uploads the master zip file to box.com" do
        expect(box_service).to receive(:upload_file).with(
          master_zip_file_path,
          "0000001"
        )

        subject
      end

      it "updates the transcription_package record" do
        expect(transcription_package.date_upload_box).to eq(nil)
        expect(transcription_package.status == "Successful Upload (BOX)").to eq false

        subject

        expect(transcription_package.date_upload_box.to_date == Time.zone.today).to eq true
        expect(transcription_package.status == "Successful Upload (BOX)").to eq true
      end

      it "updates the associated transcription records" do
        transcriptions = transcription_package.transcriptions

        transcriptions.each do |t|
          expect(t.transcription_contractor == transcription_package.contractor).to eq false
          expect(t.sent_to_transcriber_date == Time.zone.today).to eq false
          expect(t.transcription_status == "in_transcription").to eq false
        end

        subject

        transcriptions.each do |t|
          expect(t.transcription_contractor).to eq(transcription_package.contractor)
          expect(t.sent_to_transcriber_date).to eq(Time.zone.today)
          expect(t.transcription_status == "in_transcription").to eq true
        end
      end

      it "updates the associated transcription_file records" do
        TranscriptionFile.all.each do |tf|
          expect(tf.date_upload_box).to eq nil
          expect(tf.file_status == "Successful Upload (BOX)").to eq false
        end

        subject

        TranscriptionFile.all.each do |tf|
          expect(tf.date_upload_box.to_date == Time.zone.today).to eq true
          expect(tf.file_status == "Successful Upload (BOX)").to eq true
        end
      end

      it "updates vacols HEARSCHED table" do
        vacols_record = VACOLS::CaseHearing.find_by(hearing_pkseq: legacy_hearing.vacols_id)

        expect(vacols_record.taskno).to eq nil
        expect(vacols_record.contapes).to eq nil
        expect(vacols_record.consent).to eq nil
        expect(vacols_record.conret).to eq nil

        subject
        vacols_record.reload

        expect(vacols_record.taskno).to eq "11-0001"
        expect(vacols_record.contapes).to eq "D"
        expect(vacols_record.consent).to eq Time.zone.now.utc.to_date
        expect(vacols_record.conret).to eq transcription_package.expected_return_date
      end
    end

    context "sad path" do
      it "sends an email on failure to get child folder id from box.com" do
        allow(box_service).to receive(:get_child_folder_id)
          .and_return(nil)
        allow(Raven).to receive(:capture_exception)

        expect_any_instance_of(Hearings::VaBoxUploadJob).to receive(:send_transcription_issues_email).with(
          error: {
            type: "child_folder_id",
            message: "Child folder ID not found for contractor name: Contractor Name"
          },
          provider: "Box"
        )

        subject
      end

      it "sends an email on failure to upload to box.com" do
        allow_any_instance_of(described_class).to receive(:upload_master_zip_to_box)
          .and_raise(StandardError)
        allow(Raven).to receive(:capture_exception)

        expect_any_instance_of(Hearings::VaBoxUploadJob).to receive(:send_transcription_issues_email).with(
          error: { type: "upload", message: "StandardError" },
          provider: "Box"
        )

        subject
      end

      it "sends an email on failure to update db records" do
        allow_any_instance_of(described_class).to receive(:update_database_records)
          .and_raise(StandardError)
        allow(Raven).to receive(:capture_exception)

        expect_any_instance_of(Hearings::VaBoxUploadJob).to receive(:send_transcription_issues_email).with(
          error: { type: "upload", message: "StandardError" },
          provider: "Box"
        )

        subject
      end
    end
  end
end
