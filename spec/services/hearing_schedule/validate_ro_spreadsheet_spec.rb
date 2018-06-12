describe HearingSchedule::ValidateRoSpreadsheet do
  context "when CO non-availaility dates are out of range" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/outOfRange.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/03/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateRoSpreadsheet::CoDatesNotInRange)
    end
  end

  context "when CO non-availaility dates are duplicated" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/duplicateDates.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/03/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateRoSpreadsheet::CoDatesNotUnique)
    end
  end

  context "when CO non-availaility dates are the wrong format" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/wrongDataType.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/03/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateRoSpreadsheet::CoDatesNotCorrectFormat)
    end
  end

  context "when CO non-availaility dates valid" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/validRoSpreadsheet.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/03/2018")
      ).validate
    end

    it { is_expected.to be true }
  end
end
