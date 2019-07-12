# frozen_string_literal: true

require "rails_helper"

describe WarmBgsCachesJob do
  context "default" do
    # cache keys are using default POA so no specific ids.
    let(:poa_cache_key) { "bgs-participant-poa-" }
    let(:address_cache_key) { "bgs-participant-address-" }
    let(:ro_id) { "RO04" }
    let(:vacols_case) { create(:case) }
    let(:appeal) do
      create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
    end
    let(:hearing_day) do
      create(:hearing_day, request_type: "V", regional_office: ro_id, scheduled_for: Time.zone.today)
    end
    let!(:hearing) do
      create(
        :case_hearing,
        hearing_type: HearingDay::REQUEST_TYPES[:central],
        folder_nr: appeal.vacols_id,
        vdkey: hearing_day.id
      )
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
      expect(Rails.cache.exist?(poa_cache_key)).to eq(false)
      expect(Rails.cache.exist?(address_cache_key)).to eq(false)
      expect { described_class.perform_now }.to_not raise_error
      expect(bgs_poa).to have_received(:fetch_bgs_record).once
      expect(bgs_address_service).to have_received(:fetch_bgs_record).once
      expect(Rails.cache.exist?(poa_cache_key)).to eq(true)
      expect(Rails.cache.exist?(address_cache_key)).to eq(true)
    end
  end
end
