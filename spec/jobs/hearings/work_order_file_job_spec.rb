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

  subject { described_class.perform_now(work_order) }

  it "temporarily saves a xls file in the work order" do
    file_path = File.join(Rails.root, "tmp", "BVA-#{work_order[:work_order_name]}.xls")
    expect(File.exist?(file_path)).to eq false
    subject
    expect(File.exist?(file_path)).to eq true
    File.delete(file_path)
  end
end
