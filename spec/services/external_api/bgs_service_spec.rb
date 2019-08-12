# frozen_string_literal: true

describe ExternalApi::BGSService do
  let(:bgs_veteran_service) { double("veteran") }
  let(:bgs_people_service) { double("people") }
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
    end

    let(:veteran) { build(:veteran) }

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
  end
end
