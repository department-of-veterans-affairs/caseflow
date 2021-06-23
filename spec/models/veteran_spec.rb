# frozen_string_literal: true

describe Veteran, :all_dbs do
  let(:veteran) do
    Veteran.new(
      file_number: "44556677",
      first_name: "June",
      last_name: "Juniper",
      name_suffix: name_suffix,
      date_of_death: date_of_death
    )
  end

  before do
    Timecop.freeze(Time.utc(2022, 1, 15, 12, 0, 0))

    Fakes::BGSService.store_veteran_record("44556677", veteran_record)

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
      name_suffix: name_suffix,
      ssn: ssn,
      address_line1: "122 Mullberry St.",
      address_line2: "PO BOX 123",
      address_line3: address_line3,
      city: city,
      state: state,
      country: country,
      date_of_birth: date_of_birth,
      date_of_death: date_of_death,
      zip_code: zip_code,
      military_post_office_type_code: military_post_office_type_code,
      military_postal_type_code: military_postal_type_code,
      service: service
    }
  end
  let(:name_suffix) { "II" }

  let(:city) { "San Francisco" }
  let(:state) { "CA" }
  let(:military_post_office_type_code) { nil }
  let(:military_postal_type_code) { nil }
  let(:country) { "USA" }
  let(:zip_code) { "94117" }
  let(:address_line3) { "Daisies" }
  let(:date_of_birth) { "12/21/1989" }
  let(:service) { [{ branch_of_service: "army", pay_grade: "E4" }] }
  let(:date_of_death) { "12/31/2019" }
  let(:ssn) { "123456789" }

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

        it "returns nil when accessing zip_code" do
          expect(subject.zip_code).to be_nil
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
      let!(:veteran) { create(:veteran, last_name: "Smith", file_number: file_number) }

      before do
        Fakes::BGSService.edit_veteran_record(file_number, :last_name, "Changed")
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

    context "when local participant_id attribute is nil" do
      let!(:veteran) do
        veteran = create(:veteran, file_number: file_number)
        veteran.update!(participant_id: nil)
        veteran
      end
      let(:sync_name) { true }

      it "caches it like name" do
        expect(described_class.find_by(file_number: file_number)[:participant_id]).to be_nil
        described_class.find_or_create_by_file_number(file_number, sync_name: sync_name)
        expect(described_class.find_by(file_number: file_number)[:participant_id]).to_not be_nil
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
        date_of_birth: "12/21/1989",
        date_of_death: "12/31/2019",
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
        date_of_birth: "12/21/1989",
        date_of_death: Date.new(2019, 12, 31),
        zip_code: "94117",
        military_post_office_type_code: "DPO",
        military_postal_type_code: "AE"
      )
    end
  end

  context "#to_vbms_hash" do
    let(:date_of_death) { nil }
    subject { veteran.to_vbms_hash }

    it "returns the correct values" do
      is_expected.to eq(
        file_number: "44556677",
        sex: "M",
        first_name: "June",
        last_name: "Juniper",
        name_suffix: name_suffix,
        service: [{ branch_of_service: "army", pay_grade: "E4" }],
        ssn: "123456789",
        address_line1: "122 Mullberry St.",
        address_line2: "PO BOX 123",
        address_line3: "Daisies",
        date_of_death: nil,
        city: "San Francisco",
        state: "CA",
        country: "USA",
        date_of_birth: "12/21/1989",
        zip_code: "94117",
        address_type: "",
        email_address: nil
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

    context "when veteran pay grade is invalid" do
      subject { veteran.validate_veteran_pay_grade }
      let(:service) do
        [{ branch_of_service: "Army",
           entered_on_duty_date: "06282002",
           released_active_duty_date: "06282003",
           pay_grade: "not valid",
           char_of_svc_code: "TBD" }]
      end

      it "pay grade invalid" do
        expect(subject).to eq ["invalid_pay_grade"]
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

  context "#access_error" do
    subject { veteran.access_error }

    it "returns nil when the BGS record is successfully returned" do
      expect(subject).to be_nil
    end

    context "when an error is returned" do
      let(:bgs_error) { BGS::ShareError.new("No BGS record for you!") }

      before do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info)
          .and_raise(bgs_error)
      end

      it "returns the BGS error message" do
        expect(subject).to eq(bgs_error.message)
      end
    end
  end

  context "#multiple_phone_numbers?" do
    subject { veteran.multiple_phone_numbers? }

    it "returns false when the BGS record is successfully returned" do
      expect(subject).to be false
    end

    context "when an error is returned" do
      let(:bgs_error) { BGS::ShareError.new("Something went wrong") }

      before do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info)
          .and_raise(bgs_error)
      end

      it "returns false for an unrelated error" do
        expect(subject).to be false
      end

      context "when the error is the multiple phone number error" do
        let(:bgs_error) { BGS::ShareError.new("NonUniqueResultException The query on candidate type...") }

        it { is_expected.to be true }
      end
    end
  end

  context "#relationship_with_participant_id" do
    let(:relationship_participant_id) { "2019111201" }
    let(:other_participant_id) { "2019111202" }

    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(
        [
          {
            first_name: "Ilse",
            last_name: "Cerveny",
            ptcpnt_id: other_participant_id
          },
          {
            first_name: "Josephine",
            last_name: "Clark",
            ptcpnt_id: relationship_participant_id
          }
        ]
      )
    end

    subject { veteran.relationship_with_participant_id(relationship_participant_id) }

    it "returns the matching relationship" do
      expect(subject).to_not be_nil
      expect(subject.participant_id).to eq relationship_participant_id
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

  context "#ssn" do
    subject { veteran.ssn }

    context "when populated returns the value" do
      it { is_expected.to eq("123456789") }
    end

    context "when there is no ssn returns nil" do
      let(:ssn) { nil }
      it { is_expected.to eq(nil) }
    end

    context "when there is no veteran record returns nil" do
      let(:veteran_record) { nil }
      it { is_expected.to eq(nil) }
    end
  end

  context "when a zip code is invalid" do
    let(:zip_code) { "1234" }

    it "zip code has invalid characters" do
      expect(veteran.validate_zip_code).to eq ["invalid_zip_code"]
    end
  end

  context "given a military address and nil city & state" do
    let(:military_postal_type_code) { "AA" }
    let(:city) { nil }
    let(:state) { nil }
    let(:date_of_birth) { nil }

    it "is considered a valid veteran from bgs" do
      expect(veteran.valid?(:bgs)).to be true
    end
  end

  context "given a military address with invalid city characters" do
    let(:military_postal_type_code) { "AA" }
    let(:city) { "ÐÐÐÐÐ" }
    let(:state) { nil }

    it "city is considered invalid" do
      expect(veteran.validate_city).to eq ["invalid_characters"]
    end
  end

  context "given date of birth is missing leading zeros" do
    let(:date_of_birth) { "2/2/1956" }

    it "date_of_birth is considered invalid" do
      expect(veteran.validate_date_of_birth).to eq ["invalid_date_of_birth"]
    end
  end

  context "#validate_name_suffix" do
    subject { veteran.validate_name_suffix }
    let(:name_suffix) { "JR." }

    it "name_suffix is considered invalid" do
      expect(subject).to eq ["invalid_character"]
      expect(veteran.valid?(:bgs)).to eq false
    end

    context "name_suffix nil" do
      let(:name_suffix) { nil }

      it "name_suffix is considered valid" do
        subject
        expect(veteran.valid?(:bgs)).to eq true
      end
    end
  end

  context "given a military address with invalid address characters" do
    subject { veteran.validate_address_line }

    context "invalid address characters" do
      let(:address_line1) { "%%%%%" }

      it "address count" do
        expect(subject.length).to eq(3)
      end

      it "address_line1 is invalid" do
        expect(address_line1).to eq("%%%%%")
      end
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
    let(:ssn) { "666660000" }
    let!(:veteran) { create(:veteran, last_name: "Smith", file_number: file_number, ssn: ssn) }

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
        Fakes::BGSService.edit_veteran_record(file_number, :last_name, "Changed")
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
    let(:ssn) { "666660000" }

    before do
      BGSService.veteran_store.clear!
    end

    context "veteran exists in Caseflow" do
      let!(:veteran) { create(:veteran, file_number: file_number, ssn: ssn) }

      it "fetches based on file_number" do
        expect(described_class.find_or_create_by_file_number_or_ssn(file_number)).to eq(veteran)
      end

      it "fetches based on SSN" do
        expect(described_class.find_or_create_by_file_number_or_ssn(ssn)).to eq(veteran)
      end

      context "veteran saved in Caseflow with SSN as filenumber" do
        let!(:veteran_by_ssn) { create(:veteran, file_number: ssn, ssn: ssn) }

        before do
          veteran.destroy! # leaves it in BGS
        end

        it "finds the veteran based on SSN and does not create a duplicate" do
          expect(described_class.find_or_create_by_file_number_or_ssn(ssn)).to eq(veteran_by_ssn)
          expect(described_class.find_or_create_by_file_number_or_ssn(file_number)).to eq(veteran_by_ssn)
          expect(Veteran.where(ssn: ssn).count).to eq 1
        end
      end
    end

    context "does not exist in BGS" do
      let(:file_number) { "999990000" }

      subject { described_class.find_or_create_by_file_number_or_ssn(file_number) }

      it "returns nil" do
        subject
        expect(described_class.find_by(file_number: file_number)).to be_nil
        expect(subject).to be_nil
      end
    end

    context "does not exist in Caseflow" do
      let!(:veteran) { create(:veteran, file_number: file_number, ssn: ssn) }

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
      let!(:veteran) { create(:veteran, last_name: "Smith", file_number: file_number, ssn: ssn) }

      before do
        Fakes::BGSService.edit_veteran_record(veteran.file_number, :last_name, "Changed")
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

  describe "#unload_bgs_record" do
    subject { veteran.unload_bgs_record }

    it "uses the new address for establishing a claim" do
      expect(veteran.bgs_record[:address_line1]).to eq("122 Mullberry St.")

      Fakes::BGSService.edit_veteran_record(veteran.file_number, :address_line1, "Changed")

      subject

      expect(veteran.bgs_record[:address_line1]).to eq("Changed")
    end
  end

  describe "#stale_attributes?" do
    let(:first_name) { "Jane" }
    let(:last_name) { "Doe" }
    let(:middle_name) { "Q" }
    let(:name_suffix) { "Esq" }
    let(:ssn) { "666000000" }
    let(:date_of_death) { "2019-12-31" }
    let(:bgs_first_name) { first_name }
    let(:bgs_last_name) { last_name }
    let(:bgs_middle_name) { middle_name }
    let(:bgs_name_suffix) { name_suffix }
    let(:bgs_ssn) { ssn }
    let(:bgs_date_of_death) { date_of_death }
    let!(:veteran) do
      create(
        :veteran,
        first_name: first_name,
        last_name: last_name,
        middle_name: middle_name,
        name_suffix: name_suffix,
        ssn: ssn,
        date_of_death: date_of_death,
        bgs_veteran_record: {
          first_name: bgs_first_name,
          last_name: bgs_last_name,
          middle_name: bgs_middle_name,
          name_suffix: bgs_name_suffix,
          ssn: bgs_ssn,
          date_of_death: bgs_date_of_death
        }
      )
    end

    subject { veteran.stale_attributes? }

    before do
      veteran.unload_bgs_record # force it to reload from BGS
    end

    context "no difference" do
      it "is false" do
        is_expected.to eq(false)
      end
    end

    context "date_of_death does not match BGS" do
      let(:bgs_date_of_death) { "2020-01-02" }

      before do
        Fakes::BGSService.edit_veteran_record(veteran.file_number, :date_of_death, bgs_date_of_death)
      end

      it "is true" do
        is_expected.to eq(true)
      end

      it "updates date_of_death_death_reported_at" do
        expect(veteran.date_of_death_reported_at).to eq(Time.zone.now)
      end
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

    context "ssn does not match BGS" do
      let(:bgs_ssn) { "666999999" }

      before do
        Fakes::BGSService.edit_veteran_record(veteran.file_number, :ssn, bgs_ssn)
      end

      it { is_expected.to eq(true) }
    end
  end

  context "#zip_code" do
    subject do
      veteran.zip_code
    end

    it { is_expected.to eq("94117") }
  end

  describe "#date_of_death" do
    context "when nil is cached and BGS returns a date of death" do
      let(:date_of_death) { nil }
      let(:new_date_of_death) { Date.new(2021, 3, 8) }
      let(:bgs_date_of_death) { "03/08/2021" }
      before do
        allow(veteran).to receive(:fetch_bgs_record).and_return(date_of_death: bgs_date_of_death)
      end

      subject { veteran.date_of_death }
      it "saves the non-nil value to Caseflow DB" do
        expect(subject).to eq(new_date_of_death)
        expect(veteran[:date_of_death]).to eq(new_date_of_death)
      end
    end
  end

  describe "#update_cached_attributes!" do
    let(:new_date_of_death) { Date.new(2021, 3, 8) }
    let(:bgs_date_of_death) { "03/08/2021" }
    before do
      allow(veteran).to receive(:fetch_bgs_record).and_return(date_of_death: bgs_date_of_death)
    end

    subject { veteran.update_cached_attributes! }

    context "when date of death is present" do
      it "saves date of death in the correct date format" do
        expect(veteran.bgs_last_synced_at).to be_nil
        subject
        expect(veteran[:date_of_death]).to eq(new_date_of_death)
        expect(veteran.bgs_last_synced_at).to eq(Time.zone.now)
      end
    end
  end
end
