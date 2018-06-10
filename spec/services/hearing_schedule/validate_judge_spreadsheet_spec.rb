describe HearingSchedule::ValidateJudgeSpreadsheet do
  context "when CO non-availaility dates are out of range" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
          Roo::Spreadsheet.open("spec/support/judgeDuplicateDates.xlsx", extension: :xlsx),
          Date.parse("01/01/2018"),
          Date.parse("01/03/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateJudgeSpreadsheet::CoDatesNotInRange)
    end
  end

  context "when Judge non-availaility dates valid" do
    subject do
      HearingSchedule::ValidateJudgeSpreadsheet.new(
          Roo::Spreadsheet.open("spec/support/validJudgeSpreadsheet.xlsx", extension: :xlsx),
          Date.parse("01/01/2018"),
          Date.parse("01/03/2018")
      ).validate
    end

    it { is_expected.to be true }
  end
end
