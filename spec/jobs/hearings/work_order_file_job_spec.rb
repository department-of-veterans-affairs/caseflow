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
  let(:file_path) { File.join(Rails.root, "tmp", "BVA-#{work_order[:work_order_name]}.xls") }

  subject { described_class.perform_now(work_order) }

  it "temporarily saves a xls file in the work order" do
    expect(File.exist?(file_path)).to eq false
    subject
    expect(File.exist?(file_path)).to eq true
    File.delete(file_path)
  end

  describe "Excel file content" do
    let(:work_order_file) { Spreadsheet.open(file_path) }
    before do
      subject
      work_order_file
    end

    after do
      File.delete(file_path) if File.exist?(file_path)
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
end
