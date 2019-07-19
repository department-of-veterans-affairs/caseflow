# frozen_string_literal: true

describe ExternalApi::BGSService do
  let(:bgs_veteran_service) { double("veteran") }
  let(:bgs_client) { double("BGS::Services") }
  let(:bgs) { ExternalApi::BGSService.new(client: bgs_client) }
  let(:veteran_record) { { name: "foo", ssn: "123" } }
  let(:user) { build(:user) }
  let(:vbms_id) { "55554444" }

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
      end
    end
  end
end
