# frozen_string_literal: true

describe HearingSchedule::ValidateJudgeSpreadsheet, :all_dbs do
  let!(:judge_stuart) { create(:user, full_name: "Stuart Huels", css_id: "BVAHUELS") }
  let!(:judge_doris) { create(:user, full_name: "Doris Lamphere", css_id: "BVALAMPHERE") }

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

  context "when spreadsheet data is valid" do
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
