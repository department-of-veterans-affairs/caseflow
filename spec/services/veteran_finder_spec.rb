# frozen_string_literal: true

describe VeteranFinder do
  before do
    Fakes::BGSService.veteran_records = { file_number => veteran_record }
    RequestStore[:current_user] = create(:user)
  end

  let(:file_number) { "44556677" }
  let(:ssn) { "123456789" }

  let(:veteran_record) do
    {
      file_number: file_number,
      ptcpnt_id: "123123",
      sex: "M",
      first_name: "June",
      middle_name: "Janice",
      last_name: "Juniper",
      name_suffix: "II",
      ssn: ssn,
      address_line1: "122 Mullberry St.",
      address_line2: "PO BOX 123",
      address_line3: address_line3,
      city: city,
      state: state,
      country: country,
      date_of_birth: date_of_birth,
      zip_code: zip_code,
      military_post_office_type_code: military_post_office_type_code,
      military_postal_type_code: military_postal_type_code,
      service: service
    }
  end

  let(:city) { "San Francisco" }
  let(:state) { "CA" }
  let(:military_post_office_type_code) { nil }
  let(:military_postal_type_code) { nil }
  let(:country) { "USA" }
  let(:zip_code) { "94117" }
  let(:address_line3) { "Daisies" }
  let(:date_of_birth) { "21/12/1989" }
  let(:service) { [{ branch_of_service: "army" }] }

  describe "#find_or_create_all" do
    subject { described_class.find_or_create_all(file_number, ssn) }

    context "Veteran record does not exist" do
      it "returns array of Veterans matching file_number" do
        expect(Veteran.find_by_file_number(file_number)).to be_nil
        expect(subject).to eq([Veteran.find_by_file_number(file_number)])
      end
    end
  end
end
