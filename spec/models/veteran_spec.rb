require "rails_helper"

describe Veteran do
  let(:veteran) { Veteran.new(file_number: "44556677") }

  before do
    Timecop.freeze(Time.utc(2022, 1, 15, 12, 0, 0))

    Fakes::BGSService.veteran_records = { "44556677" => veteran_record }
  end

  let(:veteran_record) do
    {
      file_number: "44556677",
      ptcpnt_id: "123123",
      sex: "M",
      first_name: "June",
      last_name: "Juniper",
      ssn: "123456789",
      address_line1: "122 Mullberry St.",
      address_line2: "PO BOX 123",
      address_line3: address_line3,
      city: "San Francisco",
      state: "CA",
      country: country,
      date_of_birth: date_of_birth,
      zip_code: zip_code,
      military_post_office_type_code: military_post_office_type_code,
      military_postal_type_code: military_postal_type_code,
      service: service
    }
  end

  let(:military_post_office_type_code) { nil }
  let(:military_postal_type_code) { nil }
  let(:country) { "USA" }
  let(:zip_code) { "94117" }
  let(:address_line3) { "Daisies" }
  let(:date_of_birth) { "21/12/1989" }
  let(:service) { [{ branch_of_service: "army" }] }

  context ".find_or_create_by_file_number" do
    subject { Veteran.find_or_create_by_file_number(file_number) }

    let(:file_number) { "444555666" }

    context "when veteran exists in the DB" do
      let!(:saved_veteran) do
        Veteran.create!(file_number: file_number, participant_id: "123123")
      end

      it { is_expected.to eq(saved_veteran) }
    end

    context "when veteran doesn't exist in the DB" do
      let(:file_number) { "44556677" }

      context "when veteran is found in BGS" do
        it "saves and returns veteran" do
          expect(subject.participant_id).to eq("123123")

          expect(subject.reload).to have_attributes(
            file_number: "44556677",
            participant_id: "123123"
          )
        end

        context "when duplicate veteran is saved while fetching BGS data (race condition)" do
          let(:saved_veteran) do
            Veteran.new(file_number: file_number, participant_id: "123123")
          end

          before do
            allow(Veteran).to receive(:before_create_veteran_by_file_number) do
              saved_veteran.save!
            end
          end

          it { is_expected.to eq(saved_veteran) }
        end
      end

      context "when veteran isn't found in BGS" do
        let(:file_number) { "88556677" }

        it { is_expected.to be nil }
      end
    end
  end

  context "lazily loaded bgs attributes" do
    subject { veteran }

    let(:veteran_record) do
      {
        file_number: "44556677",
        ptcpnt_id: "123123",
        sex: "M",
        first_name: "June",
        last_name: "Juniper",
        ssn: "123456789",
        address_line1: "122 Mullberry St.",
        address_line2: "PO BOX 123",
        address_line3: "Daisies",
        city: "San Francisco",
        state: "CA",
        country: "USA",
        date_of_birth: "21/12/1989",
        zip_code: "94117",
        military_post_office_type_code: "DPO",
        military_postal_type_code: "AE",

        # test extra values from BGS go unused
        chaff: "chaff"
      }
    end

    context "when veteran does not exist in BGS" do
      before do
        veteran.file_number = "DOESNOTEXIST"
      end

      it { is_expected.to_not be_found }
    end

    context "when veteran has no BIRLS record" do
      let(:veteran_record) do
        { file_number: nil }
      end

      it { is_expected.to_not be_found }
    end

    context "when veteran is inaccessible" do
      before do
        Fakes::BGSService.inaccessible_appeal_vbms_ids = ["44556677"]
      end

      it { is_expected.to be_found }
    end

    it "returns the veteran with data loaded from BGS" do
      is_expected.to have_attributes(
        file_number: "44556677",
        participant_id: "123123",
        sex: "M",
        first_name: "June",
        last_name: "Juniper",
        ssn: "123456789",
        address_line1: "122 Mullberry St.",
        address_line2: "PO BOX 123",
        address_line3: "Daisies",
        city: "San Francisco",
        state: "CA",
        country: "USA",
        date_of_birth: "21/12/1989",
        zip_code: "94117",
        military_post_office_type_code: "DPO",
        military_postal_type_code: "AE"
      )
    end
  end

  context "#to_vbms_hash" do
    subject { veteran.to_vbms_hash }

    it "returns the correct values" do
      is_expected.to eq(
        file_number: "44556677",
        sex: "M",
        first_name: "June",
        last_name: "Juniper",
        service: [{ branch_of_service: "army" }],
        ssn: "123456789",
        address_line1: "122 Mullberry St.",
        address_line2: "PO BOX 123",
        address_line3: "Daisies",
        city: "San Francisco",
        state: "CA",
        country: "USA",
        date_of_birth: "21/12/1989",
        zip_code: "94117",
        address_type: ""
      )
    end

    context "when state represents a military address" do
      let(:military_postal_type_code) { "AA" }
      let(:military_post_office_type_code) { "APO" }

      it { is_expected.to include(state: "AA", city: "APO", address_type: "OVR") }
    end

    context "when a zip code is nil" do
      let(:zip_code) { nil }

      context "when address line 3 contains a zip code" do
        let(:address_line3) { "055411-177" }

        it { is_expected.to include(zip_code: "055411-177") }
      end

      context "when address line 3 does not contain a zip code" do
        let(:address_line3) { ".4646-99" }

        it { is_expected.to include(zip_code: nil) }
      end
    end

    context "when country is not USA" do
      let(:country) { "Australia" }

      it { is_expected.to include(address_type: "INT") }

      context "when state represents a military address" do
        let(:military_postal_type_code) { "AA" }
        let(:military_post_office_type_code) { "DPO" }

        it { is_expected.to include(state: "AA", city: "DPO", address_type: "OVR") }
      end
    end
  end

  context "#accessible?" do
    subject { veteran.accessible? }

    context "when veteran is too sensitive for user" do
      before do
        Fakes::BGSService.inaccessible_appeal_vbms_ids = ["44556677"]
      end

      it { is_expected.to eq(false) }
    end

    context "when veteran is not too sensitive for user" do
      before do
        Fakes::BGSService.inaccessible_appeal_vbms_ids = ["445567"]
      end

      it { is_expected.to eq(true) }
    end
  end

  context "#periods_of_service" do
    subject { veteran.periods_of_service }

    context "when a veteran served in multiple places" do
      let(:service) do
        [{ branch_of_service: "Army",
           entered_on_duty_date: "06282002",
           released_active_duty_date: "06282003",
           char_of_svc_code: "HON" },
         { branch_of_service: "Navy",
           entered_on_duty_date: "06282006",
           released_active_duty_date: "06282008",
           char_of_svc_code: "DVA" }]
      end

      it do
        is_expected.to eq ["Army 06/28/2002 - 06/28/2003, Honorable",
                           "Navy 06/28/2006 - 06/28/2008, Dishonorable for VA Purposes"]
      end
    end

    context "when a veteran is still serving" do
      let(:service) do
        [{ branch_of_service: "Army",
           entered_on_duty_date: "06282002",
           released_active_duty_date: nil,
           char_of_svc_code: nil }]
      end

      it { is_expected.to eq ["Army 06/28/2002 - "] }
    end

    context "when a veteran does not have any service information" do
      let(:service) do
        [{ branch_of_service: nil,
           entered_on_duty_date: nil,
           released_active_duty_date: nil,
           char_of_svc_code: nil }]
      end

      it { is_expected.to eq [] }
    end

    context "when a veteran served in one place" do
      let(:service) do
        [{ branch_of_service: "Army",
           entered_on_duty_date: "06282002",
           released_active_duty_date: "06282003",
           char_of_svc_code: "HVA" },
         { branch_of_service: nil,
           entered_on_duty_date: nil,
           released_active_duty_date: nil,
           char_of_svc_code: nil }]
      end
      it { is_expected.to eq ["Army 06/28/2002 - 06/28/2003, Honorable for VA Purposes"] }
    end

    context "when a character of service code is not recognized" do
      let(:service) do
        [{ branch_of_service: "Army",
           entered_on_duty_date: "06282002",
           released_active_duty_date: "06282003",
           char_of_svc_code: "TBD" },
         { branch_of_service: nil,
           entered_on_duty_date: nil,
           released_active_duty_date: nil,
           char_of_svc_code: nil }]
      end
      it { is_expected.to eq ["Army 06/28/2002 - 06/28/2003"] }
    end
  end

  context "#age" do
    subject { veteran.age }

    context "when they're born in the 1900s" do
      let(:date_of_birth) { "2/2/1956" }
      it { is_expected.to eq(65) }
    end

    context "when they're born in the 2000s" do
      let(:date_of_birth) { "2/2/2001" }
      it { is_expected.to eq(20) }
    end

    context "when the date has already passed this year" do
      let(:date_of_birth) { "1/1/1987" }
      it { is_expected.to eq(35) }
    end
  end
end
