# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe WarmBgsCachesJob, :all_dbs do
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

      appeal.veteran.update!(ssn: nil)

      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
    end

    it "fetches all hearings and warms the Rails cache" do
      slack_service = instance_double(SlackService)

      # validate data before we run job
      expect(SlackService).to receive(:new)
        .with(msg: "Updated cached attributes for 1 Veteran records", title: "WarmBgsCachesJob")
        .and_return(slack_service)
      expect(slack_service).to receive(:send_notification)
      expect(appeal.reload.veteran[:ssn]).to be_nil
      expect(Rails.cache.exist?(poa_cache_key)).to eq(false)
      expect(Rails.cache.exist?(address_cache_key)).to eq(false)

      # run job w/o error
      expect { described_class.perform_now }.to_not raise_error

      # validate data after job
      expect(bgs_poa).to have_received(:fetch_bgs_record).once
      expect(bgs_address_service).to have_received(:fetch_bgs_record).once
      expect(Rails.cache.exist?(poa_cache_key)).to eq(true)
      expect(Rails.cache.exist?(address_cache_key)).to eq(true)
      expect(appeal.veteran.reload[:ssn]).to_not be_nil
    end
  end
end
