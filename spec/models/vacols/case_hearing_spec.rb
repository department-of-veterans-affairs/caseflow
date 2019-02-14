require "rails_helper"

describe VACOLS::CaseHearing do
  describe "#master_record_type" do
    it "returns nil if folder_nr is nil" do
      hearing = create(:case_hearing, folder_nr: nil)

      expect(hearing.master_record_type).to be_nil
    end
  end

  it "returns :video if folder_nr contains the string VIDEO" do
    hearing = create(:case_hearing, folder_nr: "VIDEO 123")

    expect(hearing.master_record_type).to eq :video
  end

  it "returns nil if folder_nr does not contain the string VIDEO" do
    hearing = create(:case_hearing, folder_nr: "123")

    expect(hearing.master_record_type).to be_nil
  end
end
