# frozen_string_literal: true

describe Api::V2::HearingSerializer do
  let(:hearing_day) do
    build(
      :hearing_day,
      regional_office: "RO01",
      request_type: HearingDay::REQUEST_TYPES[:video]
    )
  end

  subject do
    Api::V2::HearingSerializer.new(hearing).serializable_hash[:data][:attributes]
  end

  context "hearing with no location" do
    let(:hearing) do
      build(
        :hearing,
        hearing_day: hearing_day,
        hearing_location: nil,
        scheduled_in_timezone: "America/New_York"
      )
    end

    it "has expected attributes after serialization", :aggregate_failures do
      expect(subject[:city]).to eq "Boston"
      expect(subject[:state]).to eq "MA"
      expect(subject[:hearing_location]).to eq "Boston regional office"
      expect(subject[:timezone]).to eq "America/New_York"
      expect(subject[:zip_code]).to eq "02203"
      expect(subject[:address]).to eq "15 New Sudbury Street"
      expect(subject[:scheduled_in_timezone]).to eq "America/New_York"
    end
  end

  context "hearing with alternate location" do
    let(:hearing) do
      build(
        :hearing,
        hearing_day: hearing_day,
        regional_office: "RO15"
      )
    end

    it "has expected attributes after serialization", :aggregate_failures do
      expect(subject[:city]).to eq "Huntington"
      expect(subject[:state]).to eq "WV"
      expect(subject[:hearing_location]).to eq "Huntington regional office"
      expect(subject[:timezone]).to eq "America/Kentucky/Louisville"
      expect(subject[:zip_code]).to eq "25701"
      expect(subject[:address]).to eq "640 4th Avenue"
    end
  end
end
