# frozen_string_literal: true

describe TranscriptionPackageFactory, :postgres do
  describe "#initialize" do
    let(:user) { create(:user) }
    it "creates transcription_packages record" do
      expect(TranscriptionPackage.count).to eq 0
      date_time_now = DateTime.now
      data = {
        aws_link_zip: "aws_link/zip_file",
        aws_link_work_order: "aws_link/work_order",
        created_by_id: user.id,
        task_number: "#12345",
        returned_at: date_time_now,
        date_upload_box: date_time_now,
        date_upload_aws: date_time_now
      }
      TranscriptionPackageFactory.new(data)
      expect(TranscriptionPackage.count).to eq 1
    end
  end
end
