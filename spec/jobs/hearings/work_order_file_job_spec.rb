# frozen_string_literal: true

describe Hearings::WorkOrderFileJob, type: :job do
  include ActiveJob::TestHelper

  let(:hearing) { create(:hearing) }
  let(:work_order) do
    {
      work_order_name: "#12347767",
      return_date: "02/12/2024",
      contractor: "Contractor Name",
      hearings: [{ hearing_id: hearing.id, hearing_type: hearing.class.to_s }]
    }
  end
  let(:file_path) { Rails.root.join("tmp/transcription_files/xls/#{work_order[:work_order_name]}.xls") }

  subject { described_class.perform_now(work_order) }

  def cleanup_tmp_file
    File.delete(file_path) if File.exist?(file_path)
  end

  it "temporarily saves a xls file in the work order" do
    allow_any_instance_of(described_class).to receive(:cleanup_tmp_file).and_return(nil)
    expect(File.exist?(file_path)).to eq false
    subject
    expect(File.exist?(file_path)).to eq true
    cleanup_tmp_file
  end

  describe "Excel file content" do
    let(:work_order_file) { Spreadsheet.open(file_path) }
    before do
      allow_any_instance_of(described_class).to receive(:cleanup_tmp_file).and_return(nil)
      subject
      work_order_file
    end

    after do
      cleanup_tmp_file
    end

    it "reads the data correctly" do
      expect(work_order_file.worksheet(0).row(0)).to eq(["Work Order", work_order[:work_order_name]])
      expect(work_order_file.worksheet(0).row(2)).to eq(["Return Date", work_order[:return_date]])
      expect(work_order_file.worksheet(0).row(4)).to eq(["Contractor Name", work_order[:contractor]])
    end

    it "reads the table header correctly" do
      expect(work_order_file.worksheet(0).row(6)).to eq([
                                                          "DOCKET NUMBER",
                                                          "FIRST NAME",
                                                          "LAST NAME",
                                                          "TYPES",
                                                          "HEARING DATE",
                                                          "RO",
                                                          "VLJ",
                                                          "APPEAL TYPE"
                                                        ])
    end

    it "reads the table data rows correctly" do
      expect(work_order_file.worksheet(0).row(7)).to eq([
                                                          hearing.appeal.docket_number,
                                                          hearing.appellant_first_name,
                                                          hearing.appellant_last_name,
                                                          hearing.appeal.type,
                                                          hearing.appeal.hearing_day_if_schedueled.strftime("%m/%d/%Y"),
                                                          hearing.regional_office.name,
                                                          hearing.judge.full_name,
                                                          "AMA"
                                                        ])
    end
  end

  describe "Upload to S3" do
    before do
      hearing
    end
    it "should upload the file to S3 bucket" do
      expect(S3Service).to receive(:store_file).with(
        "vaec-appeals-caseflow-test/transcript_text/#{work_order[:work_order_name]}.xls",
        file_path,
        :filepath
      )
      expect(subject).to eq true
    end

    it "should retry and send notification on S3 upload failure" do
      expect(S3Service).to receive(:store_file).exactly(5).times.and_raise(StandardError)
      expect(WorkOrderFileIssuesMailer).to receive(:send_notification).once
      perform_enqueued_jobs { subject }
    end
  end
end
