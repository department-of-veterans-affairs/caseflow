describe HearingSchedule::ValidateRoSpreadsheet do
  context "when RO non-availaility dates are out of range" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/roOutOfRange.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateRoSpreadsheet::RoDatesNotInRange)
    end
  end

  context "when RO non-availaility dates are duplicated" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/roDuplicateDates.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateRoSpreadsheet::RoDatesNotUnique)
    end
  end

  context "when RO non-availaility dates are the wrong format" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/roWrongDataType.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateRoSpreadsheet::RoDatesNotCorrectFormat)
    end
  end

  context "when RO isn't in the system" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/roNotInSystem.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateRoSpreadsheet::RoNotInSystem)
    end
  end

  context "when RO is missing" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/roNotListed.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns an error" do
      expect { subject }.to raise_error(HearingSchedule::ValidateRoSpreadsheet::RoHearingListDoesNotMatch)
    end
  end

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

  context "when RO spreadsheet is valid" do
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
