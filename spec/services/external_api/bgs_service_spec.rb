# frozen_string_literal: true

describe ExternalApi::BGSService do
  let(:bgs_veteran_service) { double("veteran") }
  let(:bgs_people_service) { double("people") }
  let(:bgs_security_service) { double("security") }
  let(:bgs_claimants_service) { double("claimants") }
  let(:bgs_address_service) { double("address") }
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

  describe "#may_modify?" do
    subject { bgs.may_modify?(vbms_id, veteran.participant_id) }

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

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "when Veteran's spouse is an employee at same station as user" do
      let(:employee_dtos) do
        {
          ptcpnt_id: veteran.participant_id,
          station: { ptcpnt_id: "456", ptcpnt_rlnshp_type_nm: "Spouse", station_number: user.station_id }
        }
      end

      it "returns false" do
        expect(subject).to be_falsey
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

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "when Veteran is an employee at the same station as the User" do
      before do
        allow(bgs_claimants_service).to receive(:find_flashes) { fail BGS::ShareError, "no access" }
      end

      it "returns false" do
        expect(subject).to be_falsey
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

      it "returns false" do
        expect(subject).to be_falsey
      end
    end
  end
end
