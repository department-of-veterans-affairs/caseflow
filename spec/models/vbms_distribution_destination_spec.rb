# frozen_string_literal: true

describe VbmsDistributionDestination, :postgres do
  let(:distribution) { VbmsDistribution.new }

  shared_examples "destination has valid attributes" do
    it "is valid with valid attributes" do
      expect(destination).to be_valid
    end
  end

  let(:destination) do
    VbmsDistributionDestination.new(
      destination_type: "domesticAddress",
      vbms_distribution: distribution,
      address_line_1: "address line 1",
      city: "city",
      state: "NY",
      postal_code: "11385",
      country_code: "US"
    )
  end

  include_examples "destination has valid attributes"

  it "is not valid without a destination type" do
    destination.destination_type = nil
    expect(destination).to_not be_valid
  end

  it "is not valid with incorrect destination type" do
    destination.destination_type = "DomesticAddress"
    expect(destination).to_not be_valid
  end

  it "is not valid without an associated VbmsDistribution" do
    destination.vbms_distribution = nil
    expect(destination).to_not be_valid
  end

  shared_examples "destination is a physical mailing address" do
    it "is not valid without an address line 1" do
      destination.address_line_1 = nil
      expect(destination).to_not be_valid
    end

    it "is not valid without an address line 2 if treat_line_2_as_addressee is true" do
      destination.treat_line_2_as_addressee = true
      destination.address_line_2 = nil
      expect(destination).to_not be_valid
    end

    it "is not valid without an address line 3 if treat_line_3_as_addressee is true" do
      destination.treat_line_3_as_addressee = true
      destination.address_line_3 = nil
      expect(destination).to_not be_valid
    end

    it "is not valid without a city" do
      destination.city = nil
      expect(destination).to_not be_valid
    end

    it "is not valid without a country code" do
      destination.country_code = nil
      expect(destination).to_not be_valid
    end

    it "is not valid without a two-letter ISO 3166-2 country code" do
      destination.country_code = "XX"
      expect(destination).to_not be_valid
    end
  end

  shared_examples "destination is a US address" do
    it "is not valid without a state" do
      destination.state = nil
      expect(destination).to_not be_valid
    end

    it "is not valid without a two-letter ISO 3166-2 state code" do
      destination.state = "XX"
      expect(destination).to_not be_valid
    end

    it "is not valid without a postal code" do
      destination.postal_code = nil
      expect(destination).to_not be_valid
    end
  end

  context "destination type is domesticAddress" do
    include_examples "destination has valid attributes"
    include_examples "destination is a physical mailing address"
    include_examples "destination is a US address"
  end

  context "destination type is militaryAddress" do
    let(:destination) do
      VbmsDistributionDestination.new(
        destination_type: "militaryAddress",
        vbms_distribution: distribution,
        address_line_1: "address line 1",
        city: "city",
        state: "NY",
        postal_code: "11385",
        country_code: "US"
      )
    end

    include_examples "destination has valid attributes"
    include_examples "destination is a physical mailing address"
    include_examples "destination is a US address"
  end

  context "destination type is internationalAddress" do
    let(:destination) do
      VbmsDistributionDestination.new(
        destination_type: "internationalAddress",
        vbms_distribution: distribution,
        address_line_1: "address line 1",
        city: "city",
        country_name: "France",
        country_code: "FR"
      )
    end

    include_examples "destination has valid attributes"
    include_examples "destination is a physical mailing address"

    it "is not valid without a country name" do
      destination.country_name = nil
      expect(destination).to_not be_valid
    end
  end

  context "destination type is email" do
    let(:destination) do
      VbmsDistributionDestination.new(
        destination_type: "email",
        email_address: "email@email.com",
        vbms_distribution: distribution
      )
    end

    include_examples "destination has valid attributes"

    it "is invalid without an email address" do
      destination.email_address = nil
      expect(destination).to_not be_valid
    end
  end

  context "destination type is sms" do
    let(:destination) do
      VbmsDistributionDestination.new(
        destination_type: "sms",
        phone_number: "555-5555",
        vbms_distribution: distribution
      )
    end

    include_examples "destination has valid attributes"

    it "is invalid without a phone number" do
      destination.phone_number = nil
      expect(destination).to_not be_valid
    end
  end
end
