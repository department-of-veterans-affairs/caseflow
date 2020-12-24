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
    end
  end

  context "Warm POA and cache appeals" do
    let(:job) { described_class.new }

    shared_examples "warms poa and caches in CachedAppeal table" do
      it "warms poa and caches in CachedAppeal table", :aggregate_failures do
        subject

        expect(BgsPowerOfAttorney.all.count).to eq(1)
        expect(CachedAppeal.first.power_of_attorney_name).to eq(BgsPowerOfAttorney.first.representative_name)
      end
    end

    context "Legacy appeal with open ScheduleHearingTask" do
      before { UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals }

      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal) }

      context "priority" do
        subject { job.send(:warm_poa_and_cache_for_appeals_for_hearings_priority) }
        include_examples "warms poa and caches in CachedAppeal table"
      end

      context "most recently assigned" do
        subject { job.send(:warm_poa_and_cache_for_appeals_for_hearings_most_recent) }
        include_examples "warms poa and caches in CachedAppeal table"
      end
    end

    context "AMA appeal with open ScheduleHearingTask" do
      before { UpdateCachedAppealsAttributesJob.new.cache_ama_appeals }

      subject { job.send(:warm_poa_and_cache_for_ama_appeals_with_hearings) }

      let(:appeal) { create(:appeal) }
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal) }

      context "priority" do
        subject { job.send(:warm_poa_and_cache_for_appeals_for_hearings_priority) }
        include_examples "warms poa and caches in CachedAppeal table"
      end

      context "most recently assigned" do
        subject { job.send(:warm_poa_and_cache_for_appeals_for_hearings_most_recent) }
        include_examples "warms poa and caches in CachedAppeal table"
      end
    end

    context "Oldest Claimant" do
      subject { job.send(:warm_poa_and_cache_ama_appeals_for_oldest_claimants) }

      let!(:appeal) { create(:appeal, :with_post_intake_tasks) }

      include_examples "warms poa and caches in CachedAppeal table"
    end

    context "when BGS fails" do
      let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: legacy_appeal) }

      shared_examples "rescues error" do
        it "completes and sends warning to Slack" do
          allow_any_instance_of(SlackService).to receive(:send_notification) do |_, msg, title|
            @slack_msg = msg
            @slack_title = title
          end

          job.perform_now

          expect(job.send(:warning_msgs).count).to eq 2
          expect(@slack_msg.lines.count).to eq 2
          expect(@slack_title).to match(/\[WARN\] #{described_class}: .*/)
        end
      end

      context "BGSService fails with ECONNRESET" do
        before do
          bgs = Fakes::BGSService.new
          allow(Fakes::BGSService).to receive(:new).and_return(bgs)
          allow(bgs).to receive(:fetch_poa_by_file_number)
            .and_raise(Errno::ECONNRESET, "mocked error for testing")
        end
        include_examples "rescues error"
      end
      context "BGSService fails with Savon::HTTPError" do
        before do
          bgs = Fakes::BGSService.new
          allow(Fakes::BGSService).to receive(:new).and_return(bgs)

          httperror_mock = double("httperror")
          allow(httperror_mock).to receive(:code).and_return(408)
          allow(httperror_mock).to receive(:headers).and_return({})
          allow(httperror_mock).to receive(:body).and_return("stream timeout")
          allow(bgs).to receive(:fetch_poa_by_file_number)
            .and_raise(Savon::HTTPError, httperror_mock)
        end
        include_examples "rescues error"
      end

      context "BGSService fails with BGS::ShareError" do
        before do
          error = BGS::ShareError.new("error!")
          allow_any_instance_of(BgsPowerOfAttorney).to receive(:fetch_bgs_record).and_raise(error)
        end

        include_examples "rescues error"
      end
    end
  end
end
