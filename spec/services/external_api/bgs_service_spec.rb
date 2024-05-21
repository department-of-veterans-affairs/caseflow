# frozen_string_literal: true

describe ExternalApi::BGSService do
  let(:bgs_veteran_service) { double("veteran") }
  let(:bgs_people_service) { double("people") }
  let(:bgs_security_service) { double("security") }
  let(:bgs_claimants_service) { double("claimants") }
  let(:bgs_address_service) { double("address") }
  let(:bgs_org_service) { double("org") }
  let(:bgs_client) { double("BGS::Services") }
  let(:bgs) { ExternalApi::BGSService.new(client: bgs_client) }
  let(:veteran_record) { { name: "foo", ssn: "123" } }
  let(:user) { build(:user) }
  let(:vbms_id) { "55554444" }
  let(:cache_key) { "bgs_veteran_info_#{vbms_id}" }

  before do
    RequestStore[:current_user] = user
    allow(bgs).to receive(:fetch_veteran_info).and_call_original
    allow(bgs_client).to receive(:veteran).and_return(bgs_veteran_service)
    allow(bgs_veteran_service).to receive(:find_by_file_number) { veteran_record }
  end

  after do
    bgs.bust_fetch_veteran_info_cache(vbms_id)
  end

  describe "#sensitivity_level_for_user" do
    it "validates the user param" do
      expect { bgs.sensitivity_level_for_user(nil) }.to raise_error(RuntimeError, "Invalid user")
    end

    it "calls the security service and caches the result" do
      participant_id = "1234"
      sensitivity_level = Random.new.rand(1..9)

      expect(bgs).to receive(:get_participant_id_for_user).with(user).and_return(participant_id)
      expect(bgs_client).to receive(:security).and_return(bgs_security_service)
      expect(bgs_security_service).to receive(:find_person_scrty_log_by_ptcpnt_id)
        .with(participant_id).and_return({ scrty_level_type_cd: sensitivity_level.to_s })

      expect(bgs.sensitivity_level_for_user(user)).to eq(sensitivity_level)

      expect(Rails.cache.exist?("sensitivity_level_for_user_id_#{user.id}")).to be true
    end
  end

  describe "#sensitivity_level_for_veteran" do
    let(:veteran) { create(:veteran) }

    it "validates the veteran param" do
      expect { bgs.sensitivity_level_for_veteran(nil) }.to raise_error(RuntimeError, "Invalid veteran")
    end

    it "calls the security service and caches the result" do
      sensitivity_level = Random.new.rand(1..9)

      expect(bgs_client).to receive(:security).and_return(bgs_security_service)
      expect(bgs_security_service).to receive(:find_sensitivity_level_by_participant_id)
        .with(veteran.participant_id).and_return({ scrty_level_type_cd: sensitivity_level.to_s })

      expect(bgs.sensitivity_level_for_veteran(veteran)).to eq(sensitivity_level)

      expect(Rails.cache.exist?("sensitivity_level_for_veteran_id_#{veteran.id}")).to be true
    end
  end

  describe "#fetch_poa_by_file_number" do
    let(:participant_id) { "1234" }
    let(:poa_participant_id) { "person-pid" }
    let(:file_number) { "00001234" }

    let(:bgs_poa_claimants_file_number_response) do
      {
        person_org_name: "PARALYZED VETERANS OF AMERICA, INC.",
        person_org_ptcpnt_id: poa_participant_id,
        person_organization_name: "POA National Organization",
        relationship_name: "Power of Attorney For",
        veteran_ptcpnt_id: participant_id
      }
    end

    let(:bgs_poa_org_file_number_response) do
      {
        file_number: file_number,
        ptcpnt_id: participant_id,
        power_of_attorney: {
          legacy_poa_cd: "071",
          nm: "PARALYZED VETERANS OF AMERICA, INC.",
          org_type_nm: "POA National Organization",
          ptcpnt_id: poa_participant_id
        }
      }
    end

    before do
      allow(bgs_claimants_service).to receive(:find_poa_by_file_number) { bgs_poa_claimants_file_number_response }
      allow(bgs_org_service).to receive(:find_poas_by_file_number) { bgs_poa_org_file_number_response }
      allow(bgs_client).to receive(:claimants) { bgs_claimants_service }
      allow(bgs_client).to receive(:org) { bgs_org_service }
    end

    subject { bgs.fetch_poa_by_file_number(file_number) }

    context "use_poa_claimants feature toggle on" do
      before { FeatureToggle.enable!(:use_poa_claimants) }
      after { FeatureToggle.disable!(:use_poa_claimants) }

      it "returns POA" do
        expect(subject[:participant_id]).to eq poa_participant_id
        expect(subject[:representative_type]).to eq "Service Organization"
        expect(subject[:file_number]).to be_nil
      end
    end

    context "use_poa_claimants feature toggle off" do
      it "returns POA" do
        expect(subject[:participant_id]).to eq poa_participant_id
        expect(subject[:representative_type]).to eq "Service Organization"
        expect(subject[:file_number]).to eq file_number
      end
    end
  end

  describe "#find_address_by_participant_id" do
    let(:veteran) { build(:veteran) }

    subject { bgs.find_address_by_participant_id(veteran.participant_id) }

    before do
      allow(bgs).to receive(:find_address_by_participant_id).and_call_original
      allow(bgs_client).to receive(:address).and_return(bgs_address_service)
      allow(bgs_address_service).to receive(:find_all_by_participant_id) { address_records }
    end

    let(:address_records) do
      [
        {
          addrs_one_txt: "123 MILES ST",
          city_nm: "SHADY COVE",
          cntry_nm: "USA",
          efctv_dt: 7.days.ago,
          postal_cd: "TX",
          ptcpnt_addrs_type_nm: "FMS Payment",
          zip_prefix_nbr: "76522"
        },
        {
          addrs_one_txt: "456 Any Ave.",
          city_nm: "Cypress Grove",
          cntry_nm: "USA",
          efctv_dt: 6.days.ago,
          postal_cd: "TX",
          ptcpnt_addrs_type_nm: "VRE Mailing",
          zip_prefix_nbr: "12345"
        },
        {
          addrs_one_txt: "999 The Place",
          city_nm: "Sleepy Hollow",
          cntry_nm: "USA",
          efctv_dt: 5.days.ago,
          postal_cd: "TX",
          ptcpnt_addrs_type_nm: "Mailing",
          zip_prefix_nbr: "66666"
        }
      ]
    end

    context "when no addresses exist" do
      let(:address_records) {}

      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end

    context "when multiple addresses exist" do
      it "returns Mailing address" do
        expect(subject[:address_line_1]).to eq("999 The Place")
      end
    end

    context "when no Mailing address exists" do
      let(:address_records) do
        [
          {
            addrs_one_txt: "123 MILES ST",
            city_nm: "SHADY COVE",
            cntry_nm: "USA",
            efctv_dt: 7.days.ago,
            postal_cd: "TX",
            ptcpnt_addrs_type_nm: "FMS Payment",
            zip_prefix_nbr: "76522"
          },
          {
            addrs_one_txt: "456 Any Ave.",
            city_nm: "Cypress Grove",
            cntry_nm: "USA",
            efctv_dt: 6.days.ago,
            postal_cd: "TX",
            ptcpnt_addrs_type_nm: "VRE Mailing",
            zip_prefix_nbr: "12345"
          }
        ]
      end

      it "returns most recent by effective date" do
        expect(subject[:address_line_1]).to eq("456 Any Ave.")
      end
    end
  end

  describe "#fetch_veteran_info" do
    context "when called without previous .can_access?" do
      it "reads from BGS" do
        vet_record = bgs.fetch_veteran_info(vbms_id)

        expect(bgs_veteran_service).to have_received(:find_by_file_number).once
        expect(vet_record).to eq(veteran_record)
        expect(Rails.cache.exist?(cache_key)).to be_truthy
      end
    end

    context "when .can_access? is called first" do
      before do
        bgs.can_access?(vbms_id)
      end

      it "reads from cache" do
        vet_record = bgs.fetch_veteran_info(vbms_id)

        expect(bgs_veteran_service).to have_received(:find_by_file_number).once
        expect(vet_record).to eq(veteran_record)
        expect(Rails.cache.exist?(cache_key)).to be_truthy
      end
    end
  end

  describe "#station_conflict?" do
    subject { bgs.station_conflict?(vbms_id, veteran.participant_id) }

    before do
      allow(bgs_client).to receive(:people).and_return(bgs_people_service)
      allow(bgs_people_service).to receive(:find_employee_by_participant_id) { employee_dtos }

      allow(bgs_client).to receive(:security).and_return(bgs_security_service)
      allow(bgs_security_service).to receive(:find_sensitivity_level_by_participant_id) { sensitivity_level }

      allow(bgs_client).to receive(:claimants).and_return(bgs_claimants_service)
      allow(bgs_claimants_service).to receive(:find_flashes) { true }
    end

    let(:veteran) { build(:veteran) }
    let(:sensitivity_level) { nil }

    context "when Veteran is completely unrelated to user" do
      let(:employee_dtos) do
        { ptcpnt_id: veteran.participant_id }
      end

      it "returns false" do
        expect(subject).to be_falsey
      end
    end

    context "when Veteran's spouse is an employee at same station as user" do
      let(:employee_dtos) do
        {
          ptcpnt_id: veteran.participant_id,
          station: { ptcpnt_id: "456", ptcpnt_rlnshp_type_nm: "Spouse", station_number: user.station_id }
        }
      end

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "when Veteran is a non-VBA employee" do
      let(:employee_dtos) do
        {
          ptcpnt_id: veteran.participant_id,
          station: { ptcpnt_id: "456", ptcpnt_rlnshp_type_nm: "non-VBA employee", station_number: user.station_id }
        }
      end
      let(:sensitivity_level) do
        {
          cd: user.station_id[1..2],
          fclty_type_cd: user.station_id[0],
          scrty_level_type_cd: "6",
          sntvty_reason_type_nm: "Non-VBA Employee"
        }
      end

      it "returns false" do
        expect(subject).to be_falsey
      end
    end

    context "when Veteran is an employee at the same station as the User" do
      before do
        allow(bgs_claimants_service).to receive(:find_flashes) { fail BGS::ShareError, "no access" }
      end

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "when Veteran is a VBA employee" do
      let(:employee_dtos) do
        {
          ptcpnt_id: veteran.participant_id,
          station: { ptcpnt_id: "456", ptcpnt_rlnshp_type_nm: "VBA employee", station_number: user.station_id }
        }
      end
      let(:sensitivity_level) do
        {
          cd: user.station_id[1..2],
          fclty_type_cd: user.station_id[0],
          scrty_level_type_cd: "6",
          sntvty_reason_type_nm: "VBA Employee"
        }
      end

      it "returns true" do
        expect(subject).to be_truthy
      end
    end
  end

  describe "fetch_ratings_in_range" do
    let!(:veteran) { create(:veteran) }
    let!(:rating) { double("rating") }
    let(:start_date) { Time.zone.now - 5.years }
    let(:start_date_formatted) { start_date.to_date.to_datetime.iso8601 }
    let(:end_date) { start_date }

    before do
      allow(bgs_client).to receive(:rating).and_return rating
    end

    subject do
      bgs.fetch_ratings_in_range(participant_id: veteran.participant_id, start_date: start_date, end_date: end_date)
    end

    context "the start and end dates are the same" do
      let(:end_date_formatted) { (start_date + 1.day).to_date.to_datetime.iso8601 }

      it "formats dates correctly" do
        expect(rating)
          .to receive(:find_by_participant_id_and_date_range)
          .with(veteran.participant_id, start_date_formatted, end_date_formatted)

        subject
      end
    end

    context "the start and end dates are different" do
      let(:end_date) { Time.zone.now }
      let(:end_date_formatted) { end_date.to_date.to_datetime.iso8601 }

      it "formats dates correctly" do
        expect(rating)
          .to receive(:find_by_participant_id_and_date_range)
          .with(veteran.participant_id, start_date_formatted, end_date_formatted)

        subject
      end
    end
  end
end
