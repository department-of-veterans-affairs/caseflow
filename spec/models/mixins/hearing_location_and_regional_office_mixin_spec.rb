# frozen_string_literal: true

class MixinTest
  include HearingLocationAndRegionalOfficeMixin

  def street_address
    facility_address(key)["address_1"]
  end

  def key
    "vba_422"
  end

  def facility_address(_)
    {
      "address_1" => "15 New Sudbury Street",
      "address_2" => "JFK Federal Building",
      "address_3" => nil,
      "city" => "Boston",
      "state" => "MA",
      "zip" => "02203",
      "timezone" => "America/New_York"
    }
  end
end

describe HearingLocationAndRegionalOfficeMixin do
  let(:dummy) { MixinTest.new }

  it "returns full_street_address" do
    expect(dummy.full_street_address).to eq "15 New Sudbury Street JFK Federal Building"
  end
end
