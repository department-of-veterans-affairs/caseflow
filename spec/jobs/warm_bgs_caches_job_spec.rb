# frozen_string_literal: true

describe WarmBgsCachesJob, :all_dbs do
  context "#perform" do
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
    let!(:people) { create_list(:person, 5) }

    let!(:closed_appeal) { create(:appeal, veteran: build(:veteran)) } # no tasks
    let!(:open_appeal) { create(:appeal, :with_post_intake_tasks, veteran: build(:veteran)) }

    let(:bgs_address_service) { BgsAddressService.new }

    before do
      allow(BgsAddressService).to receive(:new).and_return(bgs_address_service)
      allow(bgs_address_service).to receive(:fetch_bgs_record).and_call_original

      appeal.veteran.update!(ssn: nil)

      @people_sync = 0
      @slack_msg = nil
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
      allow_any_instance_of(Person).to receive(:update_cached_attributes!) { @people_sync += 1 }
    end

    it "fetches all hearings and warms the Rails cache" do
      # validate data before we run job
      expect(appeal.reload.veteran[:ssn]).to be_nil
      expect(Rails.cache.exist?(address_cache_key)).to eq(false)
      expect(BgsPowerOfAttorney.all.count).to eq(1) # created by open_appeal

      # run job w/o error
      expect { described_class.perform_now }.to_not raise_error

      # validate data after job
      expect(bgs_address_service).to have_received(:fetch_bgs_record).once
      expect(Rails.cache.exist?(address_cache_key)).to eq(true)
      expect(appeal.veteran.reload[:ssn]).to_not be_nil
      expect(BgsPowerOfAttorney.all.count).to eq(1) # open_appeal
      expect(appeal.representative_name).to_not be_nil
      expect(@slack_msg).to be_nil
      expect(@people_sync).to eq(5)
    end

    context "BGS POA changes at BGS" do
      before do
        claimant_pid = open_appeal.claimant.power_of_attorney.claimant_participant_id
        new_bgs_record = { claimant_pid => Fakes::BGSServicePOA.default_vsos_mapped.first }
        new_bgs_record[claimant_pid][:claimant_participant_id] = claimant_pid
        allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids).with([claimant_pid]) do
          new_bgs_record
        end
      end

      it "updates local cache to refer to same BGSPowerOfAttorney record with different attributes" do
        expect(BgsPowerOfAttorney.all.count).to eq(1) # created by open_appeal
        expect(open_appeal.claimant.power_of_attorney).to eq(BgsPowerOfAttorney.first)

        old_poa_name = open_appeal.claimant.representative_name

        expect { described_class.perform_now }.to_not raise_error

        expect(open_appeal.reload.claimant.representative_name).to_not eq(old_poa_name)
      end
    end

    context "errors" do
      before do
        allow(Raven).to receive(:capture_exception) { @raven_called = true }
      end

      context "bgs address error" do
        before do
          allow(bgs_address_service).to receive(:fetch_bgs_record) { fail "error!" }
        end

        it "captures exceptions" do
          expect(bgs_address_service).to receive(:fetch_bgs_record).once
          expect { described_class.perform_now }.to_not raise_error
          expect(@raven_called).to eq true
        end
      end

      context "ignorable bgs error" do
        before do
          ignorable_error = BGS::TransientError.new("oops!")
          allow(bgs_address_service).to receive(:fetch_bgs_record) { fail ignorable_error }
        end

        it "re-tries once" do
          expect(bgs_address_service).to receive(:fetch_bgs_record).twice
          expect { described_class.perform_now }.to_not raise_error
          expect(@raven_called).to eq true
        end
      end

      context "bgs POA error" do
        before do
          error = BGS::ShareError.new("error!")
          allow_any_instance_of(BgsPowerOfAttorney).to receive(:fetch_bgs_record).and_raise(error)
        end

        it "captures exceptions" do
          expect { described_class.perform_now }.to_not raise_error
          expect(@raven_called).to eq true
        end
      end
    end
  end
end
