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

  context "when the judges id is not in the db" do
    subject do
      HearingSchedule::ValidateJudgeSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/judgeNotInDb.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns JudgeIdNotInDatabase (not JudgeNameNotInDatabase)" do
      expect(subject).to include HearingSchedule::ValidateJudgeSpreadsheet::JudgeIdNotInDatabase
      expect(subject).not_to include HearingSchedule::ValidateJudgeSpreadsheet::JudgeNameDoesNotMatchIdInDatabase
    end
  end

  context "when the judges id is in the db, but name is not" do
    subject do
      HearingSchedule::ValidateJudgeSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/judgeNameNotInDb.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns JudgeNameNotInDatabase (not JudgeIdNotInDatabase)" do
      expect(subject).not_to include HearingSchedule::ValidateJudgeSpreadsheet::JudgeIdNotInDatabase
      expect(subject).to include HearingSchedule::ValidateJudgeSpreadsheet::JudgeNameDoesNotMatchIdInDatabase
    end
  end

  context "when one judges id is not in the db, and one judges name is not in the db" do
    subject do
      HearingSchedule::ValidateJudgeSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/judgeOneIdAndOneNameNotInDb.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns one JudgeNameNotInDatabase and one JudgeIdNotInDatabase" do
      # Should produce one error with the judge vlj_id 862
      errors = subject.find_all do |e|
        e.instance_of?(HearingSchedule::ValidateJudgeSpreadsheet::JudgeIdNotInDatabase)
      end
      expect(errors.length).to eq 1
      expect(errors.first.to_s).to match(/862/)

      # Should produce one error with the judge vlj_id 860
      errors = subject.find_all do |e|
        e.instance_of?(HearingSchedule::ValidateJudgeSpreadsheet::JudgeNameDoesNotMatchIdInDatabase)
      end
      expect(errors.length).to eq 1
      expect(errors.first.to_s).to match(/860/)
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
