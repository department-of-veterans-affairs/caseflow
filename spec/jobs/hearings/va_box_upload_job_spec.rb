# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hearings::VaBoxUploadJob, type: :job do
  let(:box_service) { instance_double(ExternalApi::VaBoxService) }
  let(:file_info) do
    {
      work_order_name: "BVA-2039-01",
      return_date: "12/12/2024",
      contractor_name: "Jamison Pickup",
      hearings: [
        { hearing_id: 1, hearing_type: "Hearing" },
        { hearing_id: 1, hearing_type: "LegacyHearing" }
      ]
    }
  end
  let(:box_folder_id) { "255974435715" }
  let(:transcription_package) do
    instance_double(TranscriptionPackage, aws_link_zip: "s3://bucket/file.zip", contractor_id: 123, id: 1)
  end
  let(:local_file_path) { Rails.root.join("tmp", "transcription_files", "file.zip") }
  let(:user) { instance_double(User, id: 1) }

  before do
    allow(ExternalApi::VaBoxService).to receive(:new).and_return(box_service)
    allow(box_service).to receive(:fetch_access_token)
    allow(box_service).to receive(:get_child_folder_id).and_return("child_folder_id")
    allow(Caseflow::S3Service).to receive(:fetch_file).and_return(local_file_path)
    allow(box_service).to receive(:upload_file)
    allow(transcription_package).to receive(:update!)
    allow(RequestStore).to receive(:[]).with(:current_user).and_return(user)
  end

  describe "#perform" do
    context "when transcription package is found" do
      before do
        allow_any_instance_of(Hearings::VaBoxUploadJob).to receive(:find_transcription_package)
          .and_return(transcription_package)
      end

      it "uploads the file to Box and updates the transcription package" do
        expect(box_service).to receive(:upload_file).with(local_file_path, "child_folder_id")
        expect(transcription_package).to receive(:update!).with(
          date_upload_box: anything,
          status: "Successful Upload (BOX)",
          task_number: file_info[:work_order_name],
          expected_return_date: file_info[:return_date],
          updated_by_id: 1
        )

        subject.perform(file_info, box_folder_id)
      end
    end

    context "when transcription package is not found" do
      before do
        allow_any_instance_of(Hearings::VaBoxUploadJob).to receive(:find_transcription_package).and_return(nil)
      end

      it "sends an email about the missing transcription package" do
        expect_any_instance_of(Hearings::VaBoxUploadJob).to receive(:send_transcription_issues_email).with(
          error: { type: "transcription_package", message: "Transcription package not found for hearing ID: 1" },
          provider: "Box"
        )

        subject.perform(file_info, box_folder_id)
      end
    end

    context "when child folder ID is not found" do
      before do
        allow_any_instance_of(Hearings::VaBoxUploadJob).to receive(:find_transcription_package)
          .and_return(transcription_package)
        allow(box_service).to receive(:get_child_folder_id).and_return(nil)
      end

      it "sends an email about the missing child folder ID" do
        expect_any_instance_of(Hearings::VaBoxUploadJob).to receive(:send_transcription_issues_email).with(
          error: { type: "child_folder_id", message: "Child folder ID not found for contractor name: Jamison Pickup" },
          provider: "Box"
        )

        subject.perform(file_info, box_folder_id)
      end
    end
  end
end
