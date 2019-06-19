# frozen_string_literal: true

describe WarmBgsParticipantAddressCachesJob do
  context "default" do
    let(:participant_id) { "123" }
    let(:cache_key) { "bgs-participant-address-#{participant_id}" }
    let(:vacols_case) do
      create(
        :case,
        folder: create(:folder, tinum: "docket-number"),
        bfregoff: "RO04",
        bfcurloc: "57"
      )
    end
    let(:appeal) do
      create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
    end
    let!(:staff) { create(:staff, stafkey: "RO04", stc2: 2, stc3: 3, stc4: 4) }
    let(:hearing) do
      create(:case_hearing, hearing_type: HearingDay::REQUEST_TYPES[:central], folder_nr: appeal.vacols_id)
    end

    let(:bgs_poa) { BgsPowerOfAttorney.new }
    let(:bgs_address_service) { BgsAddressService.new }

    before do
      allow(BgsAddressService).to receive(:new).and_return(bgs_address_service)
      allow(bgs_address_service).to receive(:fetch_bgs_record).and_call_original
      allow(BgsPowerOfAttorney).to receive(:new).and_return(bgs_poa)
      allow(bgs_poa).to receive(:fetch_bgs_record).and_call_original
    end

    it "fetches all hearings and warms the Rails cache" do
      expect { WarmBgsParticipantAddressCachesJob.perform_now }.to_not raise_error
      expect(bgs_poa).to have_received(:fetch_bgs_record).once
      expect(bgs_address_service).to have_received(:fetch_bgs_record).once

      binding.pry

      expect(Rails.cache.exist?(cache_key)).to be_truthy
    end
  end
end
