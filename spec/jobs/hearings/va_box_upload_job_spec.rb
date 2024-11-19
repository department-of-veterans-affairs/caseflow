# frozen_string_literal: true

RSpec.describe Hearings::VaBoxUploadJob do
  include ActiveJob::TestHelper

  let(:box_service) { Fakes::VaBoxService.new }
  let(:hearing) { create(:hearing) }
  let(:legacy_hearing) { create(:legacy_hearing) }
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
      ["vtt", "mp3", "zip", "rtf"].each do |ext|
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
        expect(TranscriptionPackage.first.date_upload_box).to eq(nil)
        expect(TranscriptionPackage.first.status == "Successful Upload (BOX)").to eq false

        subject

        expect(TranscriptionPackage.first.date_upload_box.to_date == Date.today).to eq true
        expect(TranscriptionPackage.first.status == "Successful Upload (BOX)").to eq true
      end

      xit "updates the associated transcription records" do
        binding.pry
      end

      xit "updates the associated transcription_file records" do
      end

      xit "updates vacols HEARSCHED table" do
        subject { described_class.perform_now(transcription_package) }
      end
    end

    context "when child folder ID is not found" do
      before do
        allow_any_instance_of(Hearings::VaBoxUploadJob).to receive(:find_transcription_package)
          .and_return(transcription_package)
        allow(box_service).to receive(:get_child_folder_id).and_return(nil)
      end

      xit "sends an email about the missing child folder ID" do
        expect_any_instance_of(Hearings::VaBoxUploadJob).to receive(:send_transcription_issues_email).with(
          error: { type: "child_folder_id", message: "Child folder ID not found for contractor name: Jamison Pickup" },
          provider: "Box"
        )

        subject.perform(file_info, box_folder_id)
      end
    end
  end
end
