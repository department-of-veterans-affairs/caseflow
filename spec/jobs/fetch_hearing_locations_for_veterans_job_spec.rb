require "rails_helper"
require "faker"

describe FetchHearingLocationsForVeteransJob do
  let!(:job) { FetchHearingLocationsForVeteransJob.new }

  context "when there is a case in location 57 *without* an associated veteran" do
    let!(:bfcorlid) { "123456789S" }
    let!(:bfcorlid_file_number) { "123456789" }
    let!(:vacols_case) { create(:case, bfcurloc: 57, bfregoff: "RO01", bfcorlid: "123456789S") }

    before(:each) do
      Fakes::BGSService.veteran_records = { "123456789" => veteran_record(file_number: "123456789S", state: "MA") }
    end

    describe "#create_missing_veterans" do
      it "creates a veteran" do
        job.create_missing_veterans
        expect(Veteran.where(file_number: bfcorlid_file_number).count).to eq 1
      end
    end

    describe "#perform" do
      let(:distance_response) { HTTPI::Response.new(200, [], mock_distance_body(distance: 11.11).to_json) }
      let(:validate_response) { HTTPI::Response.new(200, [], mock_validate_body.to_json) }
      before do
        VADotGovService = ExternalApi::VADotGovService

        allow(DataDogService).to receive(:emit_gauge).with(hash_including(metric_name: "pages_requested"), any_args).and_return("") # rubocop:disable Metrics/LineLength

        allow(MetricsService).to receive(:record).with(/GET/, any_args).and_return(distance_response)
        allow(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).and_return(distance_response)

        allow(MetricsService).to receive(:record).with(/POST/, any_args).and_return(validate_response)
        allow(HTTPI).to receive(:post).with(instance_of(HTTPI::Request)).and_return(validate_response)
      end

      it "creates an available hearing location" do
        FetchHearingLocationsForVeteransJob.perform_now
        expect(AvailableHearingLocations.count).to eq 1
        # expect(AvailableHearingLocations.first.distance).to eq 11.11
      end

      context "when closest_regional_office has to be fetched and only one RO/AHL is in veteran's state" do
        it "only fetches RO distance once" do
          expect(MetricsService).to receive(:record).with(/GET/, any_args).once
          FetchHearingLocationsForVeteransJob.perform_now
          expect(AvailableHearingLocations.count).to eq 1
        end
      end

      context "when veteran closest_regional_office is in state with multiple ROs/AHLs" do
        let(:facility_ids) do
          ohio_ro = RegionalOffice::CITIES["RO25"]
          [ohio_ro[:facility_locator_id]] + ohio_ro[:alternate_locations]
        end
        let(:distance_response) do
          HTTPI::Response.new(200, [], mock_distance_body(
            data: facility_ids.map { |id| mock_data(id: id) },
            distances: facility_ids.map { |id| mock_distance(id: id, distance: 1.1) }
          ).to_json)
        end
        let(:validate_response) { HTTPI::Response.new(200, [], mock_validate_body(state: "OH").to_json) }
        it "fetches RO distance twice" do
          expect(MetricsService).to receive(:record).with(/GET/, any_args).twice
          FetchHearingLocationsForVeteransJob.perform_now
          expect(AvailableHearingLocations.count).to eq 1
        end
      end

      context "when there is an existing available_hearing_location" do
        let(:existing_location) do
          create(:available_hearing_locations, veteran_file_number: bfcorlid_file_number, distance: 22.22)
        end

        it "deletes existing location and creates a new location" do
          FetchHearingLocationsForVeteransJob.perform_now
          expect(AvailableHearingLocations.where(distance: 22.22, veteran_file_number: bfcorlid_file_number))
            .to be_empty
          expect(AvailableHearingLocations.count).to eq 1
          # expect(AvailableHearingLocations.first.distance).to eq 11.11
        end
      end
    end

    describe "#fetch_and_update_ro_for_veteran" do
      let(:veteran) { create(:veteran, file_number: bfcorlid_file_number) }
      let(:veteran_state) { "VA" }
      let(:mock_va_dot_gov_address) do
        {
          lat: 0.0,
          long: 0.0,
          state_code: veteran_state,
          country_code: "US"
        }
      end
      let(:facility_ros) do
        RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? || ro[:state] != veteran_state }
      end
      let(:expected_ro) do
        index = RegionalOffice::CITIES.values.find_index do |ro|
          !ro[:facility_locator_id].nil? && ro[:state] == veteran_state
        end
        RegionalOffice::CITIES.keys[index]
      end
      let(:vacols_case) { create(:case, bfcurloc: 57, bfregoff: nil, bfcorlid: bfcorlid) }
      let(:body) do
        mock_distance_body(
          data: facility_ros.map { |ro| mock_data(id: ro[:facility_locator_id]) },
          distances: facility_ros.map.with_index do |ro, index|
            mock_distance(distance: index, id: ro[:facility_locator_id])
          end
        )
      end

      before do
        VADotGovService = ExternalApi::VADotGovService
        Fakes::BGSService.veteran_records = {
          "123456789": veteran_record(file_number: "123456789S", state: veteran_state)
        }

        distance_response = HTTPI::Response.new(200, [], body.to_json)
        allow(MetricsService).to receive(:record).with(/GET/, any_args).and_return(distance_response)
        allow(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).and_return(distance_response)
      end

      it "updates veteran closest_regional_office with fetched RO within veteran's state" do
        job.fetch_and_update_ro_for_veteran(veteran, va_dot_gov_address: mock_va_dot_gov_address)
        expect(Veteran.first.closest_regional_office).to eq expected_ro
      end

      context "when veteran state is outside US territories" do
        let(:mock_va_dot_gov_address) do
          {
            lat: 0.0,
            long: 0.0,
            state_code: "SS",
            country_code: "US"
          }
        end

        it "raises FetchHearingLocationsJobError" do
          expect { job.fetch_and_update_ro_for_veteran(veteran, va_dot_gov_address: mock_va_dot_gov_address) }
            .to raise_error(Caseflow::Error::FetchHearingLocationsJobError)
            .with_message("#{mock_va_dot_gov_address[:state_code]} is not a valid state code.")
        end
      end

      context "when veteran country is outside US territories" do
        let(:mock_va_dot_gov_address) do
          {
            lat: 0.0,
            long: 0.0,
            state_code: "SS",
            country_code: "CC"
          }
        end

        it "raises FetchHearingLocationsJobError" do
          expect { job.fetch_and_update_ro_for_veteran(veteran, va_dot_gov_address: mock_va_dot_gov_address) }
            .to raise_error(Caseflow::Error::FetchHearingLocationsJobError)
            .with_message(
              "#{mock_va_dot_gov_address[:country_code]} is not a valid country code."
            )
        end
      end

      context "when ROs are not found in facility locator" do
        let(:body) do
          mock_distance_body(
            data: [],
            distances: []
          )
        end

        it "raises VADotGovServiceError" do
          expect { job.fetch_and_update_ro_for_veteran(veteran, va_dot_gov_address: mock_va_dot_gov_address) }
            .to raise_error(Caseflow::Error::VaDotGovAPIError)
        end
      end

      [:GQ, :RP, :VQ].each do |country_code|
        context "when veteran country is in a US territory with country code #{country_code}" do
          let(:mock_va_dot_gov_address) do
            {
              lat: 0.0,
              long: 0.0,
              state_code: veteran_state,
              country_code: country_code.to_s
            }
          end

          let(:expected_state) do
            {
              GQ: "HI",
              RP: "PI",
              VQ: "PR"
            }[country_code]
          end

          let(:facility_ros) do
            RegionalOffice::CITIES.values.reject { |ro| ro[:facility_locator_id].nil? || ro[:state] != expected_state }
          end

          it "closest_regional_office is in appropriate state" do
            job.fetch_and_update_ro_for_veteran(veteran, va_dot_gov_address: mock_va_dot_gov_address)
            index = RegionalOffice::CITIES.values.find_index { |ro| ro[:state] == expected_state }
            expect(Veteran.first.closest_regional_office).to eq RegionalOffice::CITIES.keys[index]
          end
        end
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def veteran_record(file_number:, state: "MA")
    {
      file_number: file_number,
      ptcpnt_id: "123123",
      sex: "M",
      first_name: "June",
      middle_name: "Janice",
      last_name: "Juniper",
      name_suffix: "II",
      ssn: "123456789",
      address_line1: "122 Mullberry St.",
      address_line2: "PO BOX 123",
      address_line3: "",
      city: "Roanoke",
      state: state,
      country: "USA",
      date_of_birth: "1977-07-07",
      zip_code: "99999",
      military_post_office_type_code: "99999",
      military_postal_type_code: "99999",
      service: "99999"
    }
  end

  def mock_validate_body(lat: 38.768185, long: -77.450033, state: "MA", country_code: "US")
    {
      "address": {
        "county": {
          "name": "Manassas Park City"
        },
        "stateProvince": {
          "name": "Virginia",
          "code": state
        },
        "country": {
          "name": "United States",
          "fipsCode": country_code,
          "code": "USA"
        },
        "addressLine1": "8633 Union Pl",
        "city": "Manassas Park",
        "zipCode5": "20111"
      },
      "geocode": {
        "latitude": lat,
        "longitude": long
      }
    }
  end

  def mock_distance_body(distance: 0.0, id: "vba_301", data: nil, distances: nil)
    {
      "data": data || [mock_data(id: id)],
      "links": {
        "next": nil
      },
      "meta": {
        "distances": distances || [mock_distance(distance: distance, id: id)]
      }
    }
  end

  def mock_data(id:)
    {
      "id": id,
      "type": "va_facilities",
      "attributes": {
        "name": "Holdrege VA Clinic",
        "facility_type": "va_health_facility",
        "lat": 40.4454392100001,
        "long": -99.37959413,
        "address": {
          "physical": {
            "zip": "68949-1705",
            "city": "Holdrege",
            "state": "NE",
            "address_1": "1118 Burlington Street",
            "address_2": "",
            "address_3": nil
          }
        }
      }
    }
  end

  def mock_distance(distance:, id:)
    {
      "id": id,
      "distance": distance
    }
  end
  # rubocop:enable Metrics/MethodLength
end
