# frozen_string_literal: true

require "./app/models/batch_processes/batch_process_priority_ep_sync.rb"

describe BatchProcessPriorityEpSync, :postgres do
  before do
    Timecop.freeze(Time.utc(2022, 1, 1, 12, 0, 0))
  end

  describe ".find_records" do
    # Normal records
    let!(:pepsq_records) { create_list(:priority_end_product_sync_queue, BatchProcess::BATCH_LIMIT - 10)}

    # Pepsq Status Checks
    let!(:pepsq_pre_processing) {create(:priority_end_product_sync_queue, :pre_processing) }
    let!(:pepsq_processing) {create(:priority_end_product_sync_queue, :processing)}
    let!(:pepsq_synced) {create(:priority_end_product_sync_queue, :synced)}
    let!(:pepsq_error) {create(:priority_end_product_sync_queue, :error)}
    let!(:pepsq_stuck) {create(:priority_end_product_sync_queue, :stuck)}

    # Creating batches for state check
    let!(:bp_pre_processing) {BatchProcessPriorityEpSync.create(state: "PRE_PROCESSING")}
    let!(:bp_processing) {BatchProcessPriorityEpSync.create(state: "PROCESSING")}
    let!(:bp_complete) {BatchProcessPriorityEpSync.create(state: "COMPLETED")}

    # Batch_id of nil or batch_process.state of complete
    let!(:pepsq_batch_complete) {create(:priority_end_product_sync_queue, batch_id: bp_pre_processing.batch_id)}
    let!(:pepsq_batch_processing) {create(:priority_end_product_sync_queue, batch_id: bp_processing.batch_id)}
    let!(:pepsq_batch_pre_processing) {create(:priority_end_product_sync_queue, batch_id: bp_complete.batch_id)}

    # last_batched_at checks
    let!(:pepsq_lba_before_error_delay_ends) {create(:priority_end_product_sync_queue, last_batched_at: Time.zone.now )}
    let!(:pepsq_lba_aftere_error_delay_ends) {create(:priority_end_product_sync_queue, last_batched_at: Time.zone.now - 14.hours )}

    # testing BATCH_LIMIT
    let!(:pepsq_additional_records) { create_list(:priority_end_product_sync_queue, 6) }

    # Apply sql filter
    let(:recs) {BatchProcessPriorityEpSync.find_records}

    context "verifying that find_records method filters records accurately" do
      it "checking that the batch_id is only null or batch state: complete" do
        expect(recs.any? {|r| r.batch_id == nil}).to eq(true)
        expect(recs.any? {|r| r&.batch_process&.state == "COMPLETED"}).to eq(true)
        expect(recs.any? {|r| r&.batch_process&.state == "PRE_PROCESSING"}).to eq(false)
        expect(recs.any? {|r| r&.batch_process&.state == "PROCESSING"}).to eq(false)
      end

      it "checking that synced or stuck records are ignored" do
        expect(recs.any? {|r| r.status == "SYNCED"}).to eq(false)
        expect(recs.any? {|r| r.status == "STUCK"}).to eq(false)
      end

      it "checking that last_batched at is only ever null or over ERROR_DELAY hours old" do
        expect(recs.any? {|r| r.last_batched_at == nil}).to eq(true)
        expect(recs.include?(pepsq_lba_aftere_error_delay_ends)).to eq(true)
        expect(recs.include?(pepsq_lba_before_error_delay_ends)).to eq(false)
      end

      context "checking that the number of records in a batch doesn't exceed BATCH_LIMIT" do
        it "number of records in queue should equal size of BATCH_LIMIT + 1" do
          expect(PriorityEndProductSyncQueue.count).to eq(BatchProcess::BATCH_LIMIT + 6)
        end

        it "the number of returned PEPSQ records should match the BATCH_LIMIT" do
          expect(recs.count).to eq(BatchProcess::BATCH_LIMIT)
        end
      end
    end
  end

  describe ".create_batch!" do
    let!(:pepsq_records) { create_list(:priority_end_product_sync_queue, 10) }
    subject { BatchProcessPriorityEpSync.create_batch!(pepsq_records) }

    it "will create a new batch_process" do
      subject
      expect(BatchProcess.all.count).to eq(1)
    end

    it "will set the batch_type of the new batch_process to 'BatchProcessPriorityEpSync'" do
      expect(subject.batch_type).to eq(BatchProcessPriorityEpSync.name)
    end

    it "will set the state of the new batch_process to 'PRE_PROCESSING'" do
      expect(subject.state).to eq(Constants.BATCH_PROCESS.pre_processing)
    end

    it "will set records_attempted of the new batch_process to the number of records batched" do
      expect(subject.records_attempted).to eq(pepsq_records.count)
    end

    it "will assign the newly created batch_process batch_id to all newly batched records" do
      subject
      all_pepsq_batch_ids = pepsq_records.map(&:batch_id)
      expect(all_pepsq_batch_ids).to all(eq(subject.batch_id))
    end

    it "will set the status of each newly batched record to 'PRE_PROCESSING'" do
      subject
      all_pepsq_statuses = pepsq_records.map(&:status)
      expect(all_pepsq_statuses).to all(eq(Constants.PRIORITY_EP_SYNC.pre_processing))
    end

    it "will set the last_batched_at Date/Time of each newly batched record to the current Date/Time" do
      subject
      all_pepsq_last_batched_at_times = pepsq_records.map(&:last_batched_at)
      expect(all_pepsq_last_batched_at_times).to all(eq(Time.zone.now))
    end
  end

  describe "#process_batch!" do
    include ActiveJob::TestHelper

    let!(:canceled_hlr_epe_w_canceled_vbms_ext_claim) do
      create(:end_product_establishment, :canceled_hlr_with_canceled_vbms_ext_claim)
    end
    let!(:active_hlr_epe_w_canceled_vbms_ext_claim) do
      create(:end_product_establishment, :active_hlr_with_canceled_vbms_ext_claim)
    end
    let!(:active_hlr_epe_w_active_vbms_ext_claim) do
      create(:end_product_establishment, :active_hlr_with_active_vbms_ext_claim)
    end
    let!(:active_hlr_epe_w_cleared_vbms_ext_claim) do
      create(:end_product_establishment, :active_hlr_with_cleared_vbms_ext_claim)
    end
    let!(:cleared_hlr_epe_w_cleared_vbms_ext_claim) do
      create(:end_product_establishment, :cleared_hlr_with_cleared_vbms_ext_claim)
    end
    let!(:canceled_supp_epe_w_canceled_vbms_ext_claim) do
      create(:end_product_establishment, :canceled_supp_with_canceled_vbms_ext_claim)
    end
    let!(:active_supp_epe_w_canceled_vbms_ext_claim) do
      create(:end_product_establishment, :active_supp_with_canceled_vbms_ext_claim)
    end
    let!(:active_supp_epe_w_active_vbms_ext_claim) do
      create(:end_product_establishment, :active_supp_with_active_vbms_ext_claim)
    end
    let!(:active_supp_epe_w_cleared_vbms_ext_claim) do
      create(:end_product_establishment, :active_supp_with_canceled_vbms_ext_claim)
    end
    let!(:cleared_supp_epes_w_cleared_vbms_ext_claim) do
      create(:end_product_establishment, :cleared_supp_with_cleared_vbms_ext_claim)
    end

    let!(:all_end_product_establishments) do
      EndProductEstablishment.all
    end

    let!(:pepsq_records) do
      PopulateEndProductSyncQueueJob.perform_now
      PriorityEndProductSyncQueue.all
    end

    let!(:batch_process) { BatchProcessPriorityEpSync.create_batch!(pepsq_records) }

    subject { batch_process }

    context "when all batched records in the queue are able to sync successfully" do
      before do
        subject.process_batch!
        subject.reload
        pepsq_records.each(&:reload)
      end
      it "each batched record in the queue will have a status of 'SYNCED'" do
        all_pepsq_statuses = pepsq_records.map(&:status)
        expect(all_pepsq_statuses).to all(eq(Constants.PRIORITY_EP_SYNC.synced))
      end

      it "the batch process will have a state of 'COMPLETED'" do
        expect(batch_process.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "the number of records_attempted for the batch process will match the number of PEPSQ records batched" do
        expect(batch_process.records_attempted).to eq(pepsq_records.count)
      end

      it "the number of records_completed for the batch process will match the number of PEPSQ records synced" do
        all_synced_pepsq_records = pepsq_records.select { |record| record.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_completed).to eq(all_synced_pepsq_records.count)
      end

      it "the number of records_failed for the batch process will match the number of PEPSQ records not synced" do
        all_synced_pepsq_records = pepsq_records.reject { |record| record.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_failed).to eq(all_synced_pepsq_records.count)
      end
    end

    context "when one of the batched records fails because the synced_status and level_status_code do not match" do
      before do
        active_hlr_epe_w_cleared_vbms_ext_claim.vbms_ext_claim.update!(level_status_code: "CAN")
        allow(Rails.logger).to receive(:error)
        subject.process_batch!
        subject.reload
        pepsq_records.each(&:reload)
      end

      it "all but ONE of the batched records will have a status of 'SYNCED'" do
        synced_status_pepsq_records = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        not_synced_status_pepsq_records = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(synced_status_pepsq_records.count).to eq(pepsq_records.count - not_synced_status_pepsq_records.count)
        expect(not_synced_status_pepsq_records.count).to eq(pepsq_records.count - synced_status_pepsq_records.count)
      end

      it "the failed batched record will have a status of 'ERROR'" do
        pepsq_record_without_synced_status = pepsq_records.find { |r| r.status != Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_record_without_synced_status.status).to eq(Constants.PRIORITY_EP_SYNC.error)
      end

      it "the failed batched record will raise and log error" do
        expect(Rails.logger).to have_received(:error)
          .with("#<Caseflow::Error::PriorityEndProductSyncError: EPE synced_status does not match VBMS.>")
      end

      it "the batch process will have a state of 'COMPLETED'" do
        expect(subject.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "the number of records_attempted for the batch process will match the number of PEPSQ records batched" do
        expect(subject.records_attempted).to eq(pepsq_records.count)
      end

      it "the number of records_completed for the batch process will match the number of successfully synced records" do
        synced_pepsq_records = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(subject.records_completed).to eq(synced_pepsq_records.count)
      end

      it "the number of records_failed for the batch process will match the number of errored records" do
        failed_sync_pepsq_records = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(subject.records_failed).to eq(failed_sync_pepsq_records.count)
      end
    end

    context "when one of the batched records fails because there is no related End Product within Vbms_Ext_Claim" do
      before do
        active_hlr_epe_w_cleared_vbms_ext_claim.vbms_ext_claim.destroy!
        allow(Rails.logger).to receive(:error)
        subject.process_batch!
        subject.reload
        pepsq_records.each(&:reload)
      end

      it "all but ONE of the batched records will have a status of 'SYNCED'" do
        synced_pepsq_records = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        not_synced_pepsq_records = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(synced_pepsq_records.count).to eq(pepsq_records.count - not_synced_pepsq_records.count)
        expect(not_synced_pepsq_records.count).to eq(pepsq_records.count - synced_pepsq_records.count)
      end

      it "the failed batched record will have a status of 'ERROR'" do
        pepsq_record_without_synced_status = pepsq_records.find { |r| r.status != Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_record_without_synced_status.status).to eq(Constants.PRIORITY_EP_SYNC.error)
      end

      it "calling '.vbms_ext_claim' on the failed batched record's End Product Establishment will return nil" do
        pepsq_record_without_synced_status = pepsq_records.find { |r| r.status != Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_record_without_synced_status.end_product_establishment.vbms_ext_claim).to eq(nil)
      end

      it "the failed batched record will raise and log error" do
        expect(Rails.logger).to have_received(:error)
          .with("#<Caseflow::Error::PriorityEndProductSyncError: Claim Not In VBMS_EXT_CLAIM.>")
      end

      it "the batch process will have a state of 'COMPLETED'" do
        expect(subject.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "the number of records_attempted for the batch process will match the number of PEPSQ records batched" do
        expect(subject.records_attempted).to eq(pepsq_records.count)
      end

      it "the number of records_completed for the batch process will match the number of successfully synced records" do
        synced_pepsq_records = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(subject.records_completed).to eq(synced_pepsq_records.count)
      end

      it "the number of records_failed for the batch process will match the number of errored records" do
        failed_sync_pepsq_records = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(subject.records_failed).to eq(failed_sync_pepsq_records.count)
      end
    end

    context "when one of the batched records fails because the End Product does not exist in BGS" do
      before do
        epe = EndProductEstablishment.find active_hlr_epe_w_cleared_vbms_ext_claim.id
        Fakes::EndProductStore.cache_store.redis.del("end_product_records_test:#{epe.veteran_file_number}")
        allow(Rails.logger).to receive(:error)
        subject.process_batch!
        subject.reload
        pepsq_records.each(&:reload)
      end

      it "all but ONE of the batched records will have a status of 'SYNCED'" do
        synced_pepsq_records = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        not_synced_pepsq_records = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(synced_pepsq_records.count).to eq(pepsq_records.count - not_synced_pepsq_records.count)
        expect(synced_pepsq_records.count).to eq(pepsq_records.count - 1)
        expect(not_synced_pepsq_records.count).to eq(pepsq_records.count - synced_pepsq_records.count)
        expect(not_synced_pepsq_records.count).to eq(1)
      end

      it "the failed batched record will have a status of 'ERROR'" do
        pepsq_record_without_synced_status = pepsq_records.find { |r| r.status != Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_record_without_synced_status.status).to eq(Constants.PRIORITY_EP_SYNC.error)
      end

      it "the failed batched record will raise and log error" do
        expect(Rails.logger).to have_received(:error)
          .with("#<EndProductEstablishment::EstablishedEndProductNotFound: "\
                "EndProductEstablishment::EstablishedEndProductNotFound>")
      end

      it "the batch process will have a state of 'COMPLETED'" do
        expect(subject.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "the number of records_attempted for the batch process will match the number of PEPSQ records batched" do
        expect(subject.records_attempted).to eq(pepsq_records.count)
      end

      it "the number of records_completed for the batch process will match the number of successfully synced records" do
        synced_pepsq_records = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(subject.records_completed).to eq(synced_pepsq_records.count)
      end

      it "the number of records_failed for the batch process will match the number of errored records" do
        failed_sync_pepsq_records = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(subject.records_failed).to eq(failed_sync_pepsq_records.count)
      end
    end

    context "when a batched record with a DTA/DOO disposition has a synced_status of CAN and BGS has a status of CLR" do
      let!(:veteran) { create(:veteran) }

      let!(:claimant) do
        Claimant.create!(decision_review: end_product_establishment.source,
                         participant_id: end_product_establishment.veteran.participant_id,
                         payee_code: "00")
      end

      let!(:end_product_establishment) do
        epe = create(:end_product_establishment, :active_hlr_with_canceled_vbms_ext_claim, veteran_file_number: veteran.file_number)
        EndProductEstablishment.find epe.id
      end

      let!(:hlr) do
        end_product_establishment.source
      end

      let(:contention_reference_id) { "5678" }

      let!(:request_issue) do
        create(
          :request_issue,
          decision_review: hlr,
          nonrating_issue_description: "some description",
          nonrating_issue_category: "a category",
          decision_date: 1.day.ago,
          end_product_establishment: end_product_establishment,
          contention_reference_id: contention_reference_id,
          benefit_type: hlr.benefit_type
        )
      end

      let!(:contention) do
        Generators::Contention.build(
          id: contention_reference_id,
          claim_id: end_product_establishment.reference_id,
          disposition: "Difference of Opinion"
        )
      end

      let!(:pepsq_record) do
        PriorityEndProductSyncQueue.create!(end_product_establishment_id: end_product_establishment.id)
      end

      let!(:batch_process) { BatchProcessPriorityEpSync.create_batch!([pepsq_record]) }

      before do
        end_product_establishment.sync!
        ep = end_product_establishment.result
        ep_store = Fakes::EndProductStore.new
        ep_store.update_ep_status(end_product_establishment.veteran_file_number, ep.claim_id, "CLR")
      end

      it "all request issue closed_statuses will now reflect what BGS has" do
        request_issue.reload
        expect(request_issue.closed_status).to eq("end_product_canceled")
        perform_enqueued_jobs do
          batch_process.process_batch!
        end
        request_issue.reload
        expect(request_issue.closed_status).to eq('decided')
      end

      it "all request issue closed_at date/times will be updated to when the decision issue syncing occurred " do
        request_issue.reload
        expect(request_issue.closed_at).to eq(Time.zone.now)
        future_sync_time = Timecop.travel(Time.zone.now + 1.hour)
        perform_enqueued_jobs do
          batch_process.process_batch!
        end
        request_issue.reload
        expect(request_issue.closed_at).to be > future_sync_time
      end

      it "a remanded supplemental claim will be generated" do
        expect(hlr.remand_supplemental_claims.first).to be_nil
        perform_enqueued_jobs do
          batch_process.process_batch!
        end
        hlr.reload
        expect(hlr.remand_supplemental_claims.first).to_not be_nil
        expect(hlr.remand_supplemental_claims.first.decision_review_remanded_id).to eq(hlr.id)
      end
    end
  end
end
