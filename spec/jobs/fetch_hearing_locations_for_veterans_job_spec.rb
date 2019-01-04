require "rails_helper"
require "faker"

describe FetchHearingLocationsForVeteransJob do
  let!(:job) { FetchHearingLocationsForVeteransJob.new }

  context "when there is a case in location 57 *without* an associated veteran" do
    let(:bfcorlid) { "123456789S" }
    let(:bfcorlid_file_number) { "123456789" }

    before(:each) do
      create(:case, bfcurloc: 57, bfregoff: "RO01", bfcorlid: bfcorlid)
      Fakes::BGSService.veteran_records = { bfcorlid_file_number => veteran_record(file_number: bfcorlid_file_number) }
    end

    describe "#create_missing_veterans" do
      it "creates a veteran" do
        job.create_missing_veterans
        expect(Veteran.where(file_number: bfcorlid_file_number).count).to eq 1
      end
    end

    describe "#perform" do
      before do
        VADotGovService = ExternalApi::VADotGovService

        distance_response = HTTPI::Response.new(200, [], mock_distance_body(distance: 11.11))
        expect(MetricsService).to receive(:record).with(/GET/, any_args).and_return(distance_response).once
        allow(HTTPI).to receive(:get).with(instance_of(HTTPI::Request)).and_return(distance_response)

        geocode_response = HTTPI::Response.new(200, [], mock_geocode_body)
        expect(MetricsService).to receive(:record).with(/POST/, any_args).and_return(geocode_response).once
        allow(HTTPI).to receive(:post).with(instance_of(HTTPI::Request)).and_return(geocode_response)
      end

      it "creates an available hearing location" do
        FetchHearingLocationsForVeteransJob.perform_now
        expect(AvailableHearingLocations.count).to eq 1
        expect(AvailableHearingLocations.first.distance).to eq 11.11
      end
    end

    context "and a case exists in a location other than 57" do
      before do
        create(:case, bfcurloc: 67, bfregoff: "RO10", bfcorlid: "987654321")
      end

      describe "#file_numbers" do
        it "only returns file numbers from location 57" do
          expect(job.file_numbers).to match_array [bfcorlid_file_number]
        end
      end
    end

    context "and an additional case exists in location 57 *with* an associated veteran" do
      before do
        create(:case, bfcurloc: 57, bfregoff: "RO01", bfcorlid: "987654321")
        Fakes::BGSService.veteran_records["987654321"] = veteran_record(file_number: "987654321")
        create(:veteran, file_number: "987654321")
      end

      describe "#missing_veteran_file_numbers" do
        it "returns list of file_numbers with no associated veteran" do
          expect(job.missing_veteran_file_numbers).to match_array [bfcorlid_file_number]
        end
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def veteran_record(file_number:)
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
      state: "VA",
      country: "USA",
      date_of_birth: "1977-07-07",
      zip_code: "99999",
      military_post_office_type_code: "99999",
      military_postal_type_code: "99999",
      service: "99999"
    }
  end

  def mock_geocode_body(lat: 38.768185, long: -77.450033)
    {
      "address": {
        "county": {
          "name": "Manassas Park City"
        },
        "stateProvince": {
          "name": "Virginia",
          "code": "VA"
        },
        "country": {
          "name": "United States",
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
    }.to_json
  end

  def mock_distance_body(distance: 0.0)
    {
      "data": [
        {
          "id": "vba_301",
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
      ],
      "links": {
        "next": nil
      },
      "meta": {
        "distances": [
          {
            "id": "vba_301",
            "distance": distance
          }
        ]
      }
    }.to_json
  end
  # rubocop:enable Metrics/MethodLength
end
