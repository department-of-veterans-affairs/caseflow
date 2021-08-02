# frozen_string_literal: true

describe HearingSchedule::ValidateJudgeSpreadsheet, :all_dbs do
  before do
    create(:staff, sattyid: "860", snamef: "Stuart", snamel: "Huels")
    create(:staff, sattyid: "861", snamef: "Doris", snamel: "Lamphere")
  end

  context "when the judge is not in the db" do
    subject do
      HearingSchedule::ValidateJudgeSpreadsheet.new(
        HearingSchedule::GetSpreadsheetData.new(
          Roo::Spreadsheet.open("spec/support/judgeNotInDb.xlsx", extension: :xlsx)
        )
      ).validate
    end

    it "returns JudgeNotInDatabase" do
      expect(subject).to include HearingSchedule::ValidateJudgeSpreadsheet::JudgeNotInDatabase
    end
  end

  context "when judge non-availaility dates valid" do
    subject do
      HearingSchedule::ValidateJudgeSpreadsheet.new(
        HearingSchedule::GetSpreadsheetData.new(
          Roo::Spreadsheet.open("spec/support/validJudgeSpreadsheet.xlsx", extension: :xlsx)
        )
      ).validate
    end

    it "returns an empty array" do
      expect(subject).to eq []
    end
  end
end
