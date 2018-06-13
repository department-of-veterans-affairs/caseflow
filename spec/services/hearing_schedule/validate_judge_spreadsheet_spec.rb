describe HearingSchedule::ValidateJudgeSpreadsheet do
  let(:user) { create(:default_user) }

  before do
    user.save!
  end

  context "when judge non-availaility dates are duplicated" do
    subject do
      HearingSchedule::ValidateJudgeSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/judgeDuplicateDates.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateJudgeSpreadsheet::JudgeDatesNotUnique)
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

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateJudgeSpreadsheet::JudgeDatesNotCorrectFormat)
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

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateJudgeSpreadsheet::JudgeNotInDatabase)
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

    it { is_expected.to be true }
  end
end
