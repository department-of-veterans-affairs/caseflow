# frozen_string_literal: true

describe HearingSchedule::ValidateJudgeSpreadsheet, :all_dbs do
  before do
    create(:staff, sattyid: "860", snamef: "Stuart", snamel: "Huels")
    create(:staff, sattyid: "861", snamef: "Doris", snamel: "Lamphere")
  end

  context "when judge non-availaility dates are duplicated" do
    subject do
      HearingSchedule::ValidateJudgeSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/judgeDuplicateDates.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns JudgeDatesNotUnique" do
      expect(subject).to include HearingSchedule::ValidateJudgeSpreadsheet::JudgeDatesNotUnique
    end
  end

  context "when judge non-availaility dates are not the right format" do
    subject do
      HearingSchedule::ValidateJudgeSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/judgeWrongDataType.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns JudgeDatesNotCorrectFormat" do
      expect(subject).to include HearingSchedule::ValidateJudgeSpreadsheet::JudgeDatesNotCorrectFormat
    end
  end

  context "when the judge is not in the db" do
    subject do
      HearingSchedule::ValidateJudgeSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/judgeNotInDb.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns JudgeNotInDatabase" do
      expect(subject).to include HearingSchedule::ValidateJudgeSpreadsheet::JudgeNotInDatabase
    end
  end

  context "when judge non-availaility dates valid" do
    subject do
      HearingSchedule::ValidateJudgeSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/validJudgeSpreadsheet.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns an empty array" do
      expect(subject).to eq []
    end
  end
end
