# frozen_string_literal: true

describe TimezoneService, focus: true do
  describe "#iso3166_alpha2_code_from_name" do
    shared_examples "it resolves to a valid ISO 3166 country code" do |country_name, expected_code|
      it "#{country_name.inspect} resolves to #{expected_code.inspect}" do
        country_code = described_class.iso3166_alpha2_code_from_name(country_name)
        expect(country_code).to eq(expected_code)
      end
    end

    include_examples "it resolves to a valid ISO 3166 country code", "USA", "US"
    include_examples "it resolves to a valid ISO 3166 country code", "united states", "US"
    include_examples "it resolves to a valid ISO 3166 country code", "Australia", "AU"
    include_examples "it resolves to a valid ISO 3166 country code", "Canada", "CA"
    include_examples "it resolves to a valid ISO 3166 country code", "Colombia", "CO"
    include_examples "it resolves to a valid ISO 3166 country code", "Côte d'Ivoire", "CI"
    include_examples "it resolves to a valid ISO 3166 country code", "Cote d'Ivoire", "CI"
    include_examples "it resolves to a valid ISO 3166 country code", "Dominica", "DM"
    include_examples "it resolves to a valid ISO 3166 country code", "Dominican Republic", "DO"
    include_examples "it resolves to a valid ISO 3166 country code", "Germany", "DE"
    include_examples "it resolves to a valid ISO 3166 country code", "Greenland", "GL"
    include_examples "it resolves to a valid ISO 3166 country code", "Italy", "IT"
    include_examples "it resolves to a valid ISO 3166 country code", "JAPAN", "JP"
    include_examples "it resolves to a valid ISO 3166 country code", "Philippines", "PH"
    include_examples "it resolves to a valid ISO 3166 country code", "Switzerland", "CH"
    include_examples "it resolves to a valid ISO 3166 country code", "Taiwan", "TW"
    include_examples "it resolves to a valid ISO 3166 country code", "United Kingdom", "GB"

    shared_examples "it throws an error if not a valid country name" do |country_name|
      it "#{country_name.inspect} raises InvalidCountryNameError" do
        expect do
          described_class.iso3166_alpha2_code_from_name(country_name)
        end.to raise_error(TimezoneService::InvalidCountryNameError)
      end
    end

    include_examples "it throws an error if not a valid country name", nil
    include_examples "it throws an error if not a valid country name", ""
    include_examples "it throws an error if not a valid country name", "Africa"
    include_examples "it throws an error if not a valid country name", "F R A N C E"
    include_examples "it throws an error if not a valid country name", "New York"
    include_examples "it throws an error if not a valid country name", "United St."
  end

  describe "#iso3166_alpha2_code_to_timezone" do
    shared_examples "country code resolves to timezone" do |country_code, expected_timezone_id|
      it "#{country_code.inspect} resolves to TZ (#{expected_timezone_id})" do
        timezone = described_class.iso3166_alpha2_code_to_timezone(country_code)
        expect(timezone.identifier).to eq(expected_timezone_id)
      end
    end

    include_examples "country code resolves to timezone", "CI", "Africa/Abidjan"
    include_examples "country code resolves to timezone", "CH", "Europe/Zurich"
    include_examples "country code resolves to timezone", "DM", "America/Port_of_Spain"
    include_examples "country code resolves to timezone", "JP", "Asia/Tokyo"

    shared_examples "it throws error if country code resolves to ambiguous timezone" do |country_code|
      it "#{country_code.inspect} raises AmbiguousTimezoneError" do
        expect do
          described_class.iso3166_alpha2_code_to_timezone(country_code)
        end.to raise_error(TimezoneService::AmbiguousTimezoneError)
      end
    end

    include_examples "it throws error if country code resolves to ambiguous timezone", "AU"
    include_examples "it throws error if country code resolves to ambiguous timezone", "BR"
    include_examples "it throws error if country code resolves to ambiguous timezone", "CA"
    include_examples "it throws error if country code resolves to ambiguous timezone", "CN"
    include_examples "it throws error if country code resolves to ambiguous timezone", "GL"
    include_examples "it throws error if country code resolves to ambiguous timezone", "US"
  end
end
