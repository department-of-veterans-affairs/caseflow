describe HearingSchedule::ValidateRoSpreadsheet do
  context "when CO non-availaility dates are out of range" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/coOutOfRange.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateRoSpreadsheet::CoDatesNotInRange)
    end
  end

  context "when CO non-availaility dates are duplicated" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/coDuplicateDates.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateRoSpreadsheet::CoDatesNotUnique)
    end
  end

  context "when CO non-availaility dates are the wrong format" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/coWrongDataType.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
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
        Date.parse("01/06/2018")
      ).validate
    end

    it { is_expected.to be true }
  end
end
