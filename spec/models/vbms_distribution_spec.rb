# frozen_string_literal: true

describe VbmsDistribution, :postgres do
  let(:package) { class_double(VbmsCommunicationPackage) }

  context "recipient type is nil or incorrect" do
    let(:distribution) do
      VbmsDistribution.new(
        recipient_type: nil,
        vbms_communication_package: package,
        first_name: "First",
        last_name: "Last"
      )
    end

    it "is not valid without a recipient type" do
      expect(distribution).to_not be_valid
    end

    it "is not valid with incorrect recipient type" do
      distribution.recipient_type = "Person"
      expect(distribution).to_not be_valid
    end
  end

  shared_examples "distribution has valid attributes" do
    it "is valid with valid attributes" do
      expect(distribution).to be_valid
    end
  end

  context "recipient type is person" do
    let(:distribution) do
      VbmsDistribution.new(
        recipient_type: "person",
        vbms_communication_package: package,
        first_name: "First",
        last_name: "Last"
      )
    end

    include_examples "distribution has valid attributes"

    it "is not valid without a first name" do
      distribution.first_name = nil
      expect(distribution).to be_valid
    end

    it "is not valid without a last name" do
      distribution.first_name = nil
      expect(distribution).to be_valid
    end
  end

  shared_examples "recipient type is not person" do
    it "is not valid without a name" do
      distribution.name = nil
      expect(distribution).to be_valid
    end
  end

  context "recipient type is organization" do
    let(:distribution) do
      VbmsDistribution.new(
        recipient_type: "organization",
        vbms_communication_package: package,
        name: "Organization"
      )
    end

    include_examples "distribution has valid attributes"
    include_examples "recipient type is not person"
  end

  context "recipient is system" do
    let(:distribution) do
      VbmsDistribution.new(
        recipient_type: "system",
        vbms_communication_package: package,
        name: "System"
      )
    end

    include_examples "distribution has valid attributes"
    include_examples "recipient type is not person"
  end

  context "recipient is ro-colocated" do
    let(:distribution) do
      VbmsDistribution.new(
        recipient_type: "ro-colocated",
        vbms_communication_package: package,
        name: "Ro-Colocated"
      )
    end

    include_examples "distribution has valid attributes"
    include_examples "recipient type is not person"

    it "is not valid without a poa code" do
      distribution.poa_code = nil
      expect(distribution).to be_valid
    end

    it "is not valid without a claimant station of jurisdiction" do
      distribution.claimant_station_of_jurisdiction = nil
      expect(distribution).to be_valid
    end
  end
end
