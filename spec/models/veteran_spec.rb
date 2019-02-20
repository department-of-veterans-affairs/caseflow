require "rails_helper"

describe Veteran do
  let(:veteran) { Veteran.new(file_number: "44556677", first_name: "June", last_name: "Juniper") }

  before do
    Timecop.freeze(Time.utc(2022, 1, 15, 12, 0, 0))

    Fakes::BGSService.veteran_records = { "44556677" => veteran_record }

    RequestStore[:current_user] = create(:user)
  end

  let(:veteran_record) do
    {
      file_number: "44556677",
      ptcpnt_id: "123123",
      sex: "M",
      first_name: "June",
      middle_name: "Janice",
      last_name: "Juniper",
      name_suffix: "II",
      ssn: "123456789",
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

  context ".find_or_create_by_file_number" do
    subject { Veteran.find_or_create_by_file_number(file_number, sync_name: sync_name) }

    let(:file_number) { "444555666" }
    let(:sync_name) { false }

    context "when veteran exists in the DB" do
      let!(:saved_veteran) do
        Veteran.create!(file_number: file_number, participant_id: "123123")
      end

      it { is_expected.to eq(saved_veteran) }

      context "when veteran isn't found in BGS" do
        it "does not attempt to backfill name attributes" do
          expect(subject.bgs_record).to eq(:not_found)
          expect(subject.accessible?).to eq(true)
          expect(subject.first_name).to be_nil
        end
      end
    end

    context "when veteran doesn't exist in the DB" do
      let(:file_number) { "44556677" }

      context "when veteran is found in BGS" do
        it "saves and returns veteran" do
          expect(subject.reload).to have_attributes(
            file_number: "44556677",
            participant_id: "123123",
            first_name: "June",
            middle_name: "Janice",
            last_name: "Juniper",
            name_suffix: "II"
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

    context "exists in BGS with different name than in Caseflow" do
      let!(:veteran) { create(:veteran, file_number: file_number) }

      before do
        Fakes::BGSService.veteran_records[file_number][:last_name] = "Changed"
      end

      context "sync_name flag is true" do
        let(:sync_name) { true }

        it "updates Caseflow cache when found by file number" do
          expect(described_class.find_by(file_number: file_number)[:last_name]).to eq "Smith"
          expect(described_class.find_or_create_by_file_number(file_number, sync_name: sync_name)).to eq(veteran)
          expect(veteran.reload.last_name).to eq "Changed"
        end
      end

      context "sync_name flag is false" do
        let(:sync_name) { false }

        it "does not update Caseflow cache when found by file number" do
          expect(described_class.find_by(file_number: file_number)[:last_name]).to eq "Smith"
          expect(described_class.find_or_create_by_file_number(file_number, sync_name: sync_name)).to eq(veteran)
          expect(veteran.reload.last_name).to eq "Smith"
        end

        it "no BGS method is called" do
          BGSService.instance_methods(false).each do |method_name|
            expect_any_instance_of(BGSService).not_to receive(method_name)
          end

          expect(described_class.find_or_create_by_file_number(file_number, sync_name: sync_name)).to eq(veteran)
        end
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
        name_suffix: nil,
        service: [{ branch_of_service: "army" }],
        ssn: "123456789",
        address_line1: "122 Mullberry St.",
        address_line2: "PO BOX 123",
        address_line3: "Daisies",
        date_of_death: nil,
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

      context "when address line 3 is nil" do
        let(:address_line3) { nil }

        it { is_expected.to include(zip_code: nil) }
      end

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

  context "#accessible_appeals_for_poa" do
    let!(:appeals) do
      [
        create(:appeal, veteran: veteran, claimants: [build(:claimant, participant_id: participant_id)]),
        create(:appeal, veteran: veteran, claimants: [build(:claimant, participant_id: participant_id_without_vso)])
      ]
    end

    let(:participant_id) { "1234" }
    let(:participant_id_without_vso) { "5678" }
    let(:vso_participant_id) { "2452383" }
    let(:participant_ids) { [participant_id, participant_id_without_vso] }

    let(:poas) do
      [
        {
          ptcpnt_id: participant_id,
          power_of_attorney: {
            legacy_poa_cd: "071",
            nm: "PARALYZED VETERANS OF AMERICA, INC.",
            org_type_nm: "POA National Organization",
            ptcpnt_id: vso_participant_id
          }
        },
        {
          ptcpnt_id: participant_id_without_vso,
          power_of_attorney: {}
        }
      ]
    end

    before do
      BGSService = ExternalApi::BGSService

      allow_any_instance_of(BGS::OrgWebService).to receive(:find_poas_by_ptcpnt_ids)
        .with(array_including(participant_ids)).and_return(poas)
    end

    after do
      BGSService = Fakes::BGSService
    end

    it "returns only the case with vso assigned to it" do
      returned_appeals = veteran.accessible_appeals_for_poa([vso_participant_id, "other vso participant id"])
      expect(returned_appeals.count).to eq 1
      expect(returned_appeals.first).to eq appeals.first
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

  context "given a military address and nil city & state" do
    let(:military_postal_type_code) { "AA" }
    let(:city) { nil }
    let(:state) { nil }

    it "is considered a valid veteran from bgs" do
      expect(veteran.valid?(:bgs)).to be true
    end
  end

  context "given a long address" do
    let(:address_line3) { "this address is longer than 20 chars" }

    it "is considered an invalid veteran from bgs" do
      expect(veteran.valid?(:bgs)).to be false
    end
  end

  describe ".find_by_file_number_or_ssn" do
    let(:file_number) { "123456789" }
    let(:ssn) { file_number.to_s.reverse } # our fakes do this
    let!(:veteran) { create(:veteran, file_number: file_number) }

    it "fetches based on file_number" do
      expect(described_class.find_by_file_number_or_ssn(file_number)).to eq(veteran)
    end

    it "fetches based on SSN" do
      expect(described_class.find_by_file_number_or_ssn(ssn)).to eq(veteran)
    end

    it "returns nil if a Veteran does not exist in BGS or Caseflow" do
      expect(described_class.find_by_file_number_or_ssn("000000000")).to be_nil
    end

    context "exists in BGS with different name than in Caseflow" do
      before do
        Fakes::BGSService.veteran_records[veteran.file_number][:last_name] = "Changed"
      end

      context "sync_name flag is true" do
        let(:sync_name) { true }

        it "updates Caseflow cache when found by file number" do
          expect(described_class.find_by(file_number: file_number)[:last_name]).to eq "Smith"
          expect(described_class.find_by_file_number_or_ssn(file_number, sync_name: sync_name)).to eq(veteran)
          expect(veteran.reload.last_name).to eq "Changed"
        end

        it "updates Caseflow cache when found by SSN" do
          expect(described_class.find_by(file_number: file_number)[:last_name]).to eq "Smith"
          expect(described_class.find_by_file_number_or_ssn(ssn, sync_name: sync_name)).to eq(veteran)
          expect(veteran.reload.last_name).to eq "Changed"
        end
      end

      context "sync_name flag is false" do
        let(:sync_name) { false }

        it "does not update Caseflow cache when found by file number" do
          expect(described_class.find_by(file_number: file_number)[:last_name]).to eq "Smith"
          expect(described_class.find_by_file_number_or_ssn(file_number, sync_name: sync_name)).to eq(veteran)
          expect(veteran.reload.last_name).to eq "Smith"
        end

        it "does not update Caseflow cache when found by SSN" do
          expect(described_class.find_by(file_number: file_number)[:last_name]).to eq "Smith"
          expect(described_class.find_by_file_number_or_ssn(ssn, sync_name: sync_name)).to eq(veteran)
          expect(veteran.reload.last_name).to eq "Smith"
        end
      end
    end
  end

  describe ".find_or_create_by_file_number_or_ssn" do
    let(:file_number) { "123456789" }
    let(:ssn) { file_number.to_s.reverse } # our fakes do this
    let!(:veteran) { create(:veteran, file_number: file_number) }

    it "fetches based on file_number" do
      expect(described_class.find_or_create_by_file_number_or_ssn(file_number)).to eq(veteran)
    end

    it "fetches based on SSN" do
      expect(described_class.find_or_create_by_file_number_or_ssn(ssn)).to eq(veteran)
    end

    context "does not exist in Caseflow" do
      before do
        veteran.destroy! # leaves it in BGS
      end

      it "returns a new Veteran by SSN" do
        new_veteran = described_class.find_or_create_by_file_number_or_ssn(ssn)

        expect(new_veteran.file_number).to eq(file_number)
        expect(new_veteran.id).to_not eq(veteran.id)
      end

      it "returns a new Veteran by file number" do
        new_veteran = described_class.find_or_create_by_file_number_or_ssn(file_number)

        expect(new_veteran.ssn).to eq(ssn)
        expect(new_veteran.id).to_not eq(veteran.id)
      end
    end

    context "exists in BGS with different name than in Caseflow" do
      before do
        Fakes::BGSService.veteran_records[veteran.file_number][:last_name] = "Changed"
      end

      context "sync_name flag is true" do
        let(:sync_name) { true }

        it "updates Caseflow cache when found by file number" do
          expect(described_class.find_by(file_number: file_number)[:last_name]).to eq "Smith"
          expect(described_class.find_or_create_by_file_number_or_ssn(file_number, sync_name: sync_name)).to eq(veteran)
          expect(veteran.reload.last_name).to eq "Changed"
        end

        it "updates Caseflow cache when found by SSN" do
          expect(described_class.find_by(file_number: file_number)[:last_name]).to eq "Smith"
          expect(described_class.find_or_create_by_file_number_or_ssn(ssn, sync_name: sync_name)).to eq(veteran)
          expect(veteran.reload.last_name).to eq "Changed"
        end
      end

      context "sync_name flag is false" do
        let(:sync_name) { false }

        it "does not update Caseflow cache when found by file number" do
          expect(described_class.find_by(file_number: file_number)[:last_name]).to eq "Smith"
          expect(described_class.find_or_create_by_file_number_or_ssn(file_number, sync_name: sync_name)).to eq(veteran)
          expect(veteran.reload.last_name).to eq "Smith"
        end

        it "does not update Caseflow cache when found by SSN" do
          expect(described_class.find_by(file_number: file_number)[:last_name]).to eq "Smith"
          expect(described_class.find_or_create_by_file_number_or_ssn(ssn, sync_name: sync_name)).to eq(veteran)
          expect(veteran.reload.last_name).to eq "Smith"
        end
      end
    end
  end

  describe "#stale_name?" do
    let(:first_name) { "Jane" }
    let(:last_name) { "Doe" }
    let(:middle_name) { "Q" }
    let(:name_suffix) { "Esq" }
    let(:bgs_first_name) { first_name }
    let(:bgs_last_name) { last_name }
    let(:bgs_middle_name) { middle_name }
    let(:bgs_name_suffix) { name_suffix }
    let!(:veteran) do
      create(
        :veteran,
        first_name: first_name,
        last_name: last_name,
        middle_name: middle_name,
        name_suffix: name_suffix,
        bgs_veteran_record: {
          first_name: bgs_first_name,
          last_name: bgs_last_name,
          middle_name: bgs_middle_name,
          name_suffix: bgs_name_suffix
        }
      )
    end

    subject { veteran.stale_name? }

    context "no difference" do
      it { is_expected.to eq(false) }
    end

    context "first_name is nil" do
      let(:first_name) { nil }

      it { is_expected.to eq(true) }
    end

    context "last_name is nil" do
      let(:last_name) { nil }

      it { is_expected.to eq(true) }
    end

    context "first_name does not match BGS" do
      let(:bgs_first_name) { "Changed" }

      it { is_expected.to eq(true) }
    end

    context "last_name does not match BGS" do
      let(:bgs_last_name) { "Changed" }

      it { is_expected.to eq(true) }
    end

    context "middle_name does not match BGS" do
      let(:bgs_middle_name) { "Changed" }

      it { is_expected.to eq(true) }
    end

    context "name_suffix does not match BGS" do
      let(:bgs_name_suffix) { "Changed" }

      it { is_expected.to eq(true) }
    end
  end
end
