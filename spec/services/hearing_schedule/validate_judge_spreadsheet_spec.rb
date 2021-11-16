# frozen_string_literal: true

describe HearingSchedule::ValidateJudgeSpreadsheet, :all_dbs do
  let!(:judge_stuart) { create(:user, :with_vacols_judge_record, full_name: "Stuart Huels", css_id: "BVAHUELS") }
  let!(:judge_doris) { create(:user, :with_vacols_judge_record, full_name: "Doris Lamphere", css_id: "BVALAMPHERE") }
  let!(:judge_aliana) { create(:user, :with_vacols_judge_record, full_name: "Aliana Greneven", css_id: "BVAGRENEV") }
  let!(:judge_first_james) { create(:user, :with_vacols_judge_record, full_name: "James Mulligan", css_id: "BVAMULLIGA") }
  let!(:judge_other_james) { create(:user, :with_vacols_judge_record, full_name: "James Morrigan", css_id: "BVAMORRIGA")}

  before do
    CachedUser.sync_from_vacols
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

    it "returns JudgeNotInDatabase and a hint for an incorrect name" do
      incorrect_name_text = "[\"BVALAMPHERE\", \"Huels, Stuart\", \"Name: 'Lamphere, Doris' matches CSS_ID: 'BVALAMPHERE'\"]"
      expect(subject.to_s).to include incorrect_name_text
    end

    it "returns JudgeNotInDatabase and a hint for an incorrect css_id" do
      incorrect_css_id_text = "[\"BVANULLIGAM\", nil, \"Try CSS_ID: 'BVAMULLIGA'\"]"
      expect(subject.to_s).to include incorrect_css_id_text
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
