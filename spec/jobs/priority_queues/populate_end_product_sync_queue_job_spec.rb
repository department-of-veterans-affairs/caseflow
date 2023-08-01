# frozen_string_literal: true

describe PopulateEndProductSyncQueueJob, type: :job do
  let!(:veteran) { create(:veteran) }
  let!(:found_vec) do
    create(:vbms_ext_claim, :canceled, claimant_person_id: veteran.participant_id)
  end
  let!(:found_epe) do
    create(:end_product_establishment,
           :cleared,
           veteran_file_number: veteran.file_number,
           established_at: Time.zone.today,
           reference_id: found_vec.claim_id.to_s)
  end
  let!(:not_found_epe) do
    create(:end_product_establishment,
           :canceled,
           veteran_file_number: veteran.file_number,
           established_at: Time.zone.today,
           reference_id: found_vec.claim_id.to_s)
  end
  let!(:not_found_vec) { create(:vbms_ext_claim, :rdc, claimant_person_id: veteran.participant_id) }

  before do
    # Force the job to only run long enough to iterate through the loop once.
    # This overrides the default job duration which is supposed to continue
    # iterating through the job for an hour.
    #
    # Changing the sleep duration to 0 prevents mismatching times.
    stub_const("PopulateEndProductSyncQueueJob::JOB_DURATION", 0.0001.seconds)
    stub_const("PopulateEndProductSyncQueueJob::SLEEP_DURATION", 0.seconds)
  end

  describe "#perform" do
    context "when job is able to run successfully" do
      it "adds the unsynced epe to the end product synce queue" do
        expect(PriorityEndProductSyncQueue.count).to eq 0
        PopulateEndProductSyncQueueJob.perform_now
        expect(PriorityEndProductSyncQueue.count).to eq 1
        expect(EndProductEstablishment.find(PriorityEndProductSyncQueue.first.end_product_establishment_id).reference_id).to eq found_vec.claim_id.to_s
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq found_epe.id
        expect(PriorityEndProductSyncQueue.first.status).to eq "NOT_PROCESSED"
        expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
      end

      it "doesn't add any epes if batch is empty" do
        found_epe.update!(synced_status: "CAN")
        expect(PriorityEndProductSyncQueue.count).to eq 0
        PopulateEndProductSyncQueueJob.perform_now
        expect(PriorityEndProductSyncQueue.count).to eq 0
        found_epe.update!(synced_status: "PEND")
      end

      it "doesn't add epe to queue if the epe reference_id is a lettered string (i.e. only match on matching numbers)" do
        found_epe.update!(reference_id: "wuddup yo")
        expect(PriorityEndProductSyncQueue.count).to eq 0
        PopulateEndProductSyncQueueJob.perform_now
        expect(PriorityEndProductSyncQueue.count).to eq 0
        found_epe.update!(reference_id: found_vec.claim_id.to_s)
      end

      it "will not add same epe more than once in the priorty end product sync queue table" do
        PriorityEndProductSyncQueue.create(
          end_product_establishment_id: found_epe.id
        )
        PopulateEndProductSyncQueueJob.perform_now
        expect(PriorityEndProductSyncQueue.count).to eq 1
      end

      it "will add the epe if epe synced status is nil and other conditions are met" do
        found_epe.update!(synced_status: nil)
        expect(PriorityEndProductSyncQueue.count).to eq 0
        PopulateEndProductSyncQueueJob.perform_now
        expect(PriorityEndProductSyncQueue.count).to eq 1
        found_epe.update!(synced_status: "PEND")
      end

      it "logs a message that says 'No Priority EPE Records Available'" do
        found_epe.update!(synced_status: "CAN")
        allow(Rails.logger).to receive(:info)
        PopulateEndProductSyncQueueJob.perform_now
        expect(Rails.logger).to have_received(:info).with(
          "No Priority EPE Records Available.  Job ID: #{PopulateEndProductSyncQueueJob::JOB_ATTR&.job_id}."\
          "  Time: #{Time.zone.now}"
        )
      end
    end

    context "when an error is raised during the job" do
      let!(:error) { StandardError.new("Uh-Oh!") }
      before do
        allow(Raven).to receive(:capture_exception)
        allow_any_instance_of(PopulateEndProductSyncQueueJob)
          .to receive(:find_priority_end_product_establishments_to_sync).and_raise(error)
      end

      it "the error will be sent to Sentry" do
        PopulateEndProductSyncQueueJob.perform_now
        expect(Raven).to have_received(:capture_exception)
          .with(error, extra: {})
      end
    end
  end
end
