# frozen_string_literal: true

describe TimezoneService do
  before do
    # The day the tests were written
    Timecop.freeze(Time.utc(2020, 4, 13, 12, 0, 0))
  end

  describe "#address_to_timezone" do
    let(:city) { "Test City" }
    let(:country) { nil }
    let(:state) { nil }
    let(:zip) { nil }
    let(:address) do
      Address.new(
        address_line_1: "LINE 1",
        city: city,
        country: country,
        state: state,
        zip: zip
      )
    end

    subject { TimezoneService.address_to_timezone(address) }

    context "address in the US" do
      let(:country) { "United States" }

      shared_examples "zip code resolves to timezone" do |zip_code, location, expected_timezone|
        context "zip code is in #{location}" do
          let(:zip) { zip_code }

          it "#{zip_code} resolves to timezone #{expected_timezone}" do
            expect(subject.identifier).to eq(expected_timezone)
          end
        end
      end

      # Note: The ziptz library doesn't provide super granular timezone mappings. I found cases where
      # it mapped a zip code to one with the same UTC offset, but a different than expected name.
      shared_examples "zip code resolves to equivalent timezone" do |zip_code, location, expected_timezone_name|
        context "zip code is in #{location}" do
          let(:zip) { zip_code }

          it "#{zip_code} resolves to timezone with same attributes as #{expected_timezone_name}" do
            expected_timezone = TZInfo::Timezone.get(expected_timezone_name)
            resolved_timezone = subject

            expect(resolved_timezone.identifier).not_to eq(expected_timezone_name)
            expect(resolved_timezone.current_period.offset).to eq(expected_timezone.current_period.offset)
          end
        end
      end

      include_examples "zip code resolves to timezone", "96913", "Barrigada, Guam", "Pacific/Guam"
      include_examples "zip code resolves to timezone", "79925", "El Paso, TX", "America/Denver"
      include_examples "zip code resolves to timezone", "02908", "Providence, RI", "America/New_York"
      include_examples "zip code resolves to timezone", "00601", "Puerto Rico", "America/Puerto_Rico"
      include_examples "zip code resolves to timezone", "96799", "American Samoa", "Pacific/Pago_Pago"

      # Note: These tests resolve to the incorrect IANA timezone (ex. 00803 should resolve to America/St_Thomas),
      # but the offsets from UTC are the same.
      include_examples "zip code resolves to equivalent timezone", "00803",
                       "US Virgin Islands", "America/St_Thomas"
      include_examples "zip code resolves to equivalent timezone", "96950",
                       "Northern Mariana Islands", "Pacific/Saipan"
      include_examples "zip code resolves to equivalent timezone", "96898",
                       "Wake Island, HI", "Pacific/Wake"

      context "Country name of US" do
        let(:country) { "US" }
        let(:zip) { "68107" }

        it "Valid zip code with country 'US' resolves to valid timezone" do
          expect(subject.identifier).to eq("America/Chicago")
        end
      end

      context "invalid zip code input" do
        let(:zip) { "934" }

        it { expect { subject }.to raise_error(TimezoneService::InvalidZip5Error) }
      end

      context "zip code for military address" do
        let(:zip) { "96516" }

        it { expect { subject }.to raise_error(TimezoneService::InvalidZip5Error) }
      end
    end

    context "outside of the US" do
      shared_examples "address in non-US country resolves to single timezone" do |country_name, expected_timezone|
        context "address is in #{country_name}" do
          let(:country) { country_name }

          it { expect(subject.identifier).to eq(expected_timezone) }
        end
      end

      # The timezones that are returned by TZInfo might not align with the different understandings of
      # borders/sovereignty that people from various backgrounds have. What we are more concerned about here
      # is whether or not the times are displayed correctly to different users in different regions, which
      # requires us to be consistent with the internet standards (IANA).
      #
      # See: https://github.com/tzinfo/tzinfo-data/issues/17#issuecomment-421379950
      # See: https://github.com/hexorx/countries/pull/397
      # See: https://tz.iana.narkive.com/DTtwvfsT/tz-proposal-to-use-asia-tel-aviv-for-israel-jerusalem-is-not-internationally-recognized-as-part-of
      shared_examples "address in non-US country resolves to equivalent timezone" do |country, expected_timezone_name|
        context "address is in #{country}" do
          let(:country) { country }

          it "#{country} resolves to timezone with same attributes as #{expected_timezone_name}" do
            expected_timezone = TZInfo::Timezone.get(expected_timezone_name)
            resolved_timezone = subject

            expect(resolved_timezone.current_period.offset).to eq(expected_timezone.current_period.offset)
          end

          it "time for #{country} timezone displays the same as #{expected_timezone_name}" do
            expected_timezone = TZInfo::Timezone.get(expected_timezone_name)
            resolved_timezone = subject

            expected_time_str = expected_timezone.strftime("%A, %-d %B %Y at %-l:%M%P %Z", Time.now.utc)
            resolved_time_str = resolved_timezone.strftime("%A, %-d %B %Y at %-l:%M%P %Z", Time.now.utc)

            expect(resolved_time_str).to eq(expected_time_str)
          end
        end
      end

      include_examples "address in non-US country resolves to single timezone", "Afghanistan", "Asia/Kabul"
      include_examples "address in non-US country resolves to single timezone", "Belgium", "Europe/Brussels"
      include_examples "address in non-US country resolves to single timezone", "Bulgaria", "Europe/Sofia"
      include_examples "address in non-US country resolves to equivalent timezone", "Bosnia and Herzegovina",
                       "Europe/Sarajevo"
      include_examples "address in non-US country resolves to equivalent timezone", "Cameroon", "Africa/Douala"
      include_examples "address in non-US country resolves to single timezone", "Chad", "Africa/Ndjamena"
      include_examples "address in non-US country resolves to single timezone", "Germany", "Europe/Berlin"
      include_examples "address in non-US country resolves to single timezone", "Israel", "Asia/Jerusalem"
      include_examples "address in non-US country resolves to single timezone", "Italy", "Europe/Rome"
      include_examples "address in non-US country resolves to single timezone", "Iraq", "Asia/Baghdad"
      include_examples "address in non-US country resolves to single timezone", "Japan", "Asia/Tokyo"
      include_examples "address in non-US country resolves to equivalent timezone", "Kuwait", "Asia/Kuwait"
      include_examples "address in non-US country resolves to equivalent timezone", "North Macedonia",
                       "Europe/Skopje"
      include_examples "address in non-US country resolves to single timezone", "Philippines", "Asia/Manila"
      include_examples "address in non-US country resolves to equivalent timezone", "Somalia", "Africa/Mogadishu"
      include_examples "address in non-US country resolves to single timezone", "South Korea", "Asia/Seoul"
      include_examples "address in non-US country resolves to single timezone", "Syria", "Asia/Damascus"

      shared_examples "address in non-US country has ambiguous timezone" do |country_name|
        context "address is in #{country_name}" do
          let(:country) { country_name }

          it { expect { subject }.to raise_error(TimezoneService::AmbiguousTimezoneError) }
        end
      end

      include_examples "address in non-US country has ambiguous timezone", "Australia"
      include_examples "address in non-US country has ambiguous timezone", "China"
      include_examples "address in non-US country has ambiguous timezone", "Mexico"
      include_examples "address in non-US country has ambiguous timezone", "Portugal"
    end
  end

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
    include_examples "it resolves to a valid ISO 3166 country code", "United Kingdom ", "GB"

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
    include_examples "it throws an error if not a valid country name", "US"
  end

  describe "#iso3166_alpha2_code_to_timezone" do
    shared_examples "country code resolves to timezone" do |country_code, *expected_timezone_ids|
      it "#{country_code.inspect} resolves to one of TZ (#{expected_timezone_ids})" do
        timezone = described_class.iso3166_alpha2_code_to_timezone(country_code)
        expect(timezone.identifier).to be_in(expected_timezone_ids)
      end
    end

    include_examples "country code resolves to timezone", "CI", "Africa/Abidjan"
    include_examples "country code resolves to timezone", "CH", "Europe/Zurich"
    include_examples "country code resolves to timezone", "DM", "America/Port_of_Spain", "America/Dominica"
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
