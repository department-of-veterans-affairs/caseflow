# frozen_string_literal: true

describe VeteranFinder, :postgres do
  before do
    Fakes::BGSService.store_veteran_record(file_number, veteran_record)
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

      context "BGS returns false for can_access?" do
        before do
          Fakes::BGSService.inaccessible_appeal_vbms_ids = []
          Fakes::BGSService.inaccessible_appeal_vbms_ids << file_number
          create(:veteran, participant_id: nil)
        end

        it "returns empty array" do
          expect(Fakes::BGSService.new.can_access?(file_number)).to eq(false)
          expect(Veteran.find_by_file_number(file_number)).to be_nil
          expect(subject).to eq([])
        end
      end
    end
  end

  describe "#find_best_match" do
    subject { described_class.find_best_match(ssn) }

    context "2 Veteran records with same SSN and participant id" do
      let(:ssn) { "123456789" }
      let(:participant_id) { "999000" }
      let!(:veteran1) { create(:veteran, ssn: ssn, file_number: ssn, participant_id: participant_id) }
      let!(:veteran2) { create(:veteran, ssn: ssn, file_number: "1234", participant_id: participant_id) }

      it "prefers the record with SSN != file number" do
        expect(subject).to eq(veteran2)
      end
    end

    context "SSN attribute nil" do
      let(:ssn) { "123456789" }
      let!(:veteran1) { create(:veteran, ssn: nil, file_number: ssn) }

      before do
        allow(VeteranFinder).to receive(:find_or_create_by_file_number_or_ssn) { [veteran1] }
      end

      it "does not query BGS" do
        expect(veteran1).to_not receive(:bgs_record)
        expect(subject).to eq(veteran1)
      end
    end
  end
end
