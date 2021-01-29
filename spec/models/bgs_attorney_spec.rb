# frozen_string_literal: true

describe BgsAttorney, :all_dbs do
  describe "#sync_bgs_attorneys" do
    subject { BgsAttorney.sync_bgs_attorneys }

    context "when some participant ids are already stored" do
      let!(:atty1) { create(:bgs_attorney, participant_id: "12345678", name: "JOHN SMITH") }
      let!(:atty2) { create(:bgs_attorney, participant_id: "12345679", name: "JANE DOE") }

      it "upserts all fetched attorneys" do
        subject
        expect(BgsAttorney.all.map(&:name).sort).to eq [
          "ACADIA VETERAN SERVICES",
          "JANE DOE",
          "MADELINE JENKINS",
          "NANCY BAUMBACH",
          "RANDALL KOHLER III",
          "RICH TREUTING SR."
        ]
      end
    end
  end

  describe "#warm_address_cache" do
    let(:pid) { "12345678" }
    let(:bgs_address_service) { BgsAddressService.new(participant_id: pid) }
    let(:atty) { create(:bgs_attorney, participant_id: pid, name: "JOHN SMITH") }
    let(:cache_key) { BgsAddressService.cache_key_for_participant_id(pid) }

    before do
      allow(BgsAddressService).to receive(:new).and_return(bgs_address_service)
      allow(bgs_address_service).to receive(:refresh_cached_bgs_record).and_call_original
    end

    subject { atty.warm_address_cache }

    it "fetches the attorney's address from BGS" do
      subject
      expect(BgsAddressService).to have_received(:new).with(participant_id: pid)
      expect(bgs_address_service).to have_received(:refresh_cached_bgs_record).once
      expect(Rails.cache.fetch(cache_key)).not_to be_nil
    end
  end
end
