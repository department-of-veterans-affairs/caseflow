require "rails_helper"
require "faker"

describe FetchHearingLocationsForVeteransJob do
  context "when there are appeals in locations 57 with no associated veteran" do
    before(:all) do
      @regional_office_id = "RO01"
      @bfcorlid = "123456789S"
      @bfcorlid_file_number = "123456789"
      create(:case, bfcurloc: 57, bfregoff: @regional_office_id, bfcorlid: @bfcorlid)

      veteran_record = {
        file_number: "123456789",
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

      Fakes::BGSService.veteran_records = { @bfcorlid_file_number => veteran_record }
    end

    before(:each) do
      @job = FetchHearingLocationsForVeteransJob.new
    end

    context "#file_numbers" do
      it "returns bfcorlid in CF file_number format" do
        expect(@job.file_numbers[0]).to eq @bfcorlid_file_number
      end
    end

    context "#missing_veteran_file_numbers" do
      it "returns list of file_numbers with no associated veteran" do
        expect(@job.missing_veteran_file_numbers).to match_array @job.file_numbers
      end
    end

    context "#create_missing_veterans" do
      it "creates a veteran" do
        @job.create_missing_veterans
        expect(Veteran.count).to eq 1
      end
    end

    context "#perform" do
      before do
        @distance = VADotGovService.fake_facilities_data[:meta][:distances][0][:distance]
      end

      it "creates an available hearing location" do
        FetchHearingLocationsForVeteransJob.perform_now
        expect(AvailableHearingLocations.count).to eq 1
        expect(AvailableHearingLocations.first.distance).to eq @distance
        expected_facility_id = RegionalOffice::CITIES[@regional_office_id][:facility_locator_id]
        expect(AvailableHearingLocations.first.facility_id).to eq expected_facility_id
      end
    end
  end
end
