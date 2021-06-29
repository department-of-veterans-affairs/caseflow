# frozen_string_literal: true

describe HearingSchedule::ValidateRoSpreadsheet do
  context "when RO non-availaility dates are out of range" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/roOutOfRange.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns RoDatesNotInRange" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::RoDatesNotInRange
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

    it "returns RoDatesNotUnique" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::RoDatesNotUnique
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

    it "returns RoDatesNotCorrectFormat" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::RoDatesNotCorrectFormat
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

    it "returns RoListedIncorrectly" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::RoListedIncorrectly
    end
  end

  context "when RO template not followed" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/roTemplateNotFollowed.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns RoTemplateNotFollowed" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::RoTemplateNotFollowed
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

    it "returns RoListedIncorrectly" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::RoListedIncorrectly
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

    it "returns CoDatesNotInRange" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::CoDatesNotInRange
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

    it "returns CoDatesNotUnique" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::CoDatesNotUnique
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

    it "returns CoDatesNotCorrectFormat" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::CoDatesNotCorrectFormat
    end
  end

  context "when allocation has wrong data type" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/allocationWrongDataType.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns AllocationNotCorrectFormat" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::AllocationNotCorrectFormat
    end
  end

  context "when allocation has duplicate ROs" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/allocationDuplicateRo.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns AllocationDuplicateRo" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::AllocationDuplicateRo
    end
  end

  context "when allocation template is not followed" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/allocationTemplateNotFollowed.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns AllocationTemplateNotFollowed" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::AllocationTemplateNotFollowed
    end
  end

  context "when Time Slot Details are missing" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/roMissingTimeSlotDetails.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns MissingTimeSlotDetails" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::MissingTimeSlotDetails

      expect(subject.first.message).to include("RO01")
      expect(subject.first.message).to include("RO50")
      # RO02 has 0 for virtual allocation so it does not fail
      expect(subject.first.message).not_to include("RO02")
    end
  end

  context "when Number of Time Slots Invalid" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/roInvalidNumberOfTimeSlots.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns InvalidNumberOfSlots" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::InvalidNumberOfSlots

      expect(subject.first.message).to include("RO01")
      expect(subject.first.message).to include("RO02")
      expect(subject.first.message).to include("RO49")
      # RO06 has 0 for virtual allocation so it does not fail
      expect(subject.first.message).not_to include("RO06")
    end
  end

  context "when Time Slot Duration is Invalid" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/roInvalidTimeSlotLength.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns SlotDurationExceedsMax" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::SlotDurationExceedsMax

      expect(subject.first.message).to include("RO01")
      expect(subject.first.message).to include("RO02")
      expect(subject.first.message).to include("RO59")
      # RO06 has 0 for virtual allocation so it does not fail
      expect(subject.first.message).not_to include("RO06")
    end
  end

  context "when Time Slot Start Time is Invalid" do
    subject do
      HearingSchedule::ValidateRoSpreadsheet.new(
        Roo::Spreadsheet.open("spec/support/roInvalidTimeSlotStartTime.xlsx", extension: :xlsx),
        Date.parse("01/01/2018"),
        Date.parse("01/06/2018")
      ).validate
    end

    it "returns StartTimeNotValidTime" do
      expect(subject).to include HearingSchedule::ValidateRoSpreadsheet::StartTimeNotValidTime

      expect(subject.first.message).to include("RO01")
      expect(subject.first.message).to include("RO02")
      expect(subject.first.message).to include("RO39")
      # RO06 has 0 for virtual allocation so it does not fail
      expect(subject.first.message).not_to include("RO06")
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

    it "returns an empty array" do
      expect(subject).to eq []
    end
  end
end
