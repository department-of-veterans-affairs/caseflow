# frozen_string_literal: true

describe PopulateEndProductSyncQueueJob, type: :job do
  before do
    Timecop.freeze(Time.utc(2022, 1, 1, 12, 0, 0))

    # Changing the sleep duration to 0 enables suite to run faster
    stub_const("PopulateEndProductSyncQueue::SLEEP_DURATION", 0)
    # Batch limit changes to 1 to test PopulateEndProductSyncQueueJob loop
    stub_const("PopulateEndProductSyncQueue::BATCH_LIMIT", 1)
  end

  let!(:epes_to_be_queued) do
    create_list(:end_product_establishment, 2, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:not_found_epe) do
    create(:end_product_establishment, :active_hlr_with_active_vbms_ext_claim)
  end

  describe "#perform" do
    context "when job is able to run successfully" do

      let!(:found_vec_1) { epes_to_be_queued.first.vbms_ext_claim }
      let!(:found_vec_2) { epes_to_be_queued.second.vbms_ext_claim }

      it "adds the 2 unsynced epes to the end product synce queue" do
        expect(PriorityEndProductSyncQueue.count).to eq 0
        PopulateEndProductSyncQueueJob.perform_now
        expect(PriorityEndProductSyncQueue.count).to eq 2
        expect(EndProductEstablishment.find(PriorityEndProductSyncQueue.first.end_product_establishment_id).reference_id).to eq (epes_to_be_queued.first.vbms_ext_claim.claim_id.to_s)
        expect(EndProductEstablishment.find(PriorityEndProductSyncQueue.second.end_product_establishment_id).reference_id).to eq (epes_to_be_queued.second.vbms_ext_claim.claim_id.to_s)
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq epes_to_be_queued.first.id
        expect(PriorityEndProductSyncQueue.second.end_product_establishment_id).to eq epes_to_be_queued.second.id
        expect(PriorityEndProductSyncQueue.first.status).to eq "NOT_PROCESSED"
        expect(PriorityEndProductSyncQueue.second.status).to eq "NOT_PROCESSED"
        expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
      end

      it "doesn't add any epes if batch is empty" do
        epes_to_be_queued.each { |epe| epe.update!(synced_status: "CLR") }
        expect(PriorityEndProductSyncQueue.count).to eq 0
        PopulateEndProductSyncQueueJob.perform_now
        expect(PriorityEndProductSyncQueue.count).to eq 0
        epes_to_be_queued.each { |epe| epe.update!(synced_status: "PEND") }
      end

      it "doesn't add epe to queue if the epe reference_id is a lettered string (i.e. only match on matching numbers)" do
        epes_to_be_queued.each { |epe| epe.update!(reference_id: "whaddup yooo") }
        expect(PriorityEndProductSyncQueue.count).to eq 0
        PopulateEndProductSyncQueueJob.perform_now
        expect(PriorityEndProductSyncQueue.count).to eq 0
        epes_to_be_queued.first.update!(reference_id: found_vec_1.claim_id.to_s)
        epes_to_be_queued.second.update!(reference_id: found_vec_2.claim_id.to_s)
      end

      it "will not add same epe more than once in the priorty end product sync queue table" do
        PriorityEndProductSyncQueue.create(
          end_product_establishment_id: epes_to_be_queued.first.id
        )
        PopulateEndProductSyncQueueJob.perform_now
        expect(PriorityEndProductSyncQueue.count).to eq 2
      end

      it "will add the epe if epe synced status is nil and other conditions are met" do
        epes_to_be_queued.each { |epe| epe.update!(synced_status: nil) }
        expect(PriorityEndProductSyncQueue.count).to eq 0
        PopulateEndProductSyncQueueJob.perform_now
        expect(PriorityEndProductSyncQueue.count).to eq 2
        epes_to_be_queued.each { |epe| epe.update!(synced_status: "PEND") }
      end

      it "logs a message that says 'PopulateEndProductSyncQueueJob is not able to find any batchable EPE records.'" do
        epes_to_be_queued.each { |epe| epe.update!(synced_status: "CLR")}
        allow(Rails.logger).to receive(:info)
        PopulateEndProductSyncQueueJob.perform_now
        expect(Rails.logger).to have_received(:info).with(
          "PopulateEndProductSyncQueueJob is not able to find any batchable EPE records."\
          "  Job ID: #{PopulateEndProductSyncQueueJob::JOB_ATTR&.job_id}."\
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
