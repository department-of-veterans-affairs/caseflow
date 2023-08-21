# frozen_string_literal: true

require "./app/models/batch_processes/priority_ep_sync_batch_process.rb"

describe PriorityEpSyncBatchProcess, :postgres do
  before do
    Timecop.freeze(Time.utc(2022, 1, 1, 12, 0, 0))
  end

  describe ".find_records_to_batch" do
    # Bulk creation of Pepsq records
    let!(:pepsq_records) { create_list(:priority_end_product_sync_queue, BatchProcess::BATCH_LIMIT - 10) }

    # Pepsq Records for Status Checks
    let!(:pepsq_pre_processing) { create(:priority_end_product_sync_queue, :pre_processing) }
    let!(:pepsq_processing) { create(:priority_end_product_sync_queue, :processing) }
    let!(:pepsq_synced) { create(:priority_end_product_sync_queue, :synced) }
    let!(:pepsq_error) { create(:priority_end_product_sync_queue, :error) }
    let!(:pepsq_stuck) { create(:priority_end_product_sync_queue, :stuck) }

    # Batch Processes for state check
    let!(:bp_pre_processing) { PriorityEpSyncBatchProcess.create(state: "PRE_PROCESSING") }
    let!(:bp_processing) { PriorityEpSyncBatchProcess.create(state: "PROCESSING") }
    let!(:bp_complete) { PriorityEpSyncBatchProcess.create(state: "COMPLETED") }

    # Batch_id of nil or batch_process.state of COMPLETED
    let!(:pepsq_batch_complete) { create(:priority_end_product_sync_queue, batch_id: bp_pre_processing.batch_id) }
    let!(:pepsq_batch_processing) { create(:priority_end_product_sync_queue, batch_id: bp_processing.batch_id) }
    let!(:pepsq_batch_pre_processing) { create(:priority_end_product_sync_queue, batch_id: bp_complete.batch_id) }

    # Additional records for last_batched_at checks
    let!(:pepsq_lba_before_error_delay_ends) do
      create(:priority_end_product_sync_queue, last_batched_at: Time.zone.now)
    end
    let!(:pepsq_lba_aftere_error_delay_ends) do
      create(:priority_end_product_sync_queue, last_batched_at: Time.zone.now - 14.hours)
    end

    # Additional records to test the BATCH_LIMIT
    let!(:pepsq_additional_records) { create_list(:priority_end_product_sync_queue, 6) }

    subject { PriorityEpSyncBatchProcess.find_records_to_batch }

    it "will only return records that have a NULL batch_id OR have a batch_id tied to a COMPLETED batch process" do
      expect(subject.all? { |r| r.batch_id.nil? || r.batch_process.state == "COMPLETED" }).to eq(true)
      expect(subject.all? { |r| r&.batch_process&.state == "PRE_PROCESSING" }).to eq(false)
      expect(subject.all? { |r| r&.batch_process&.state == "PROCESSING" }).to eq(false)
    end

    it "will NOT return records that have a status of SYNCED OR STUCK" do
      expect(subject.all? { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }).to eq(false)
      expect(subject.all? { |r| r.status == Constants.PRIORITY_EP_SYNC.stuck }).to eq(false)
    end

    it "will return records that have a status of NOT_PROCESSED, PRE_PROCESSING, PROCESSING, or ERROR" do
      expect(subject.all? do |r|
        r.status == Constants.PRIORITY_EP_SYNC.not_processed ||
        r.status == Constants.PRIORITY_EP_SYNC.pre_processing ||
        r.status == Constants.PRIORITY_EP_SYNC.processing ||
        r.status == Constants.PRIORITY_EP_SYNC.error
      end).to eq(true)
    end

    it "will only return records with a last_batched_at that is NULL OR outside of the ERROR_DELAY" do
      expect(subject.all? { |r| r.last_batched_at.nil? || r.last_batched_at <= BatchProcess::ERROR_DELAY.hours.ago })
        .to eq(true)
      expect(subject.include?(pepsq_lba_aftere_error_delay_ends)).to eq(true)
      expect(subject.include?(pepsq_lba_before_error_delay_ends)).to eq(false)
    end

    it "will NOT return records with a last_batched_at that is within the ERROR_DELAY" do
      expect(subject.none? do |r|
        r.last_batched_at.present? && r.last_batched_at > BatchProcess::ERROR_DELAY.hours.ago
      end).to eq(true)
    end

    it "number of records returned will not exceed the BATCH_LIMIT when available records exceed the BATCH_LIMIT" do
      expect(PriorityEndProductSyncQueue.count).to eq(BatchProcess::BATCH_LIMIT + 6)
      expect(subject.count).to eq(BatchProcess::BATCH_LIMIT)
    end
  end

  describe ".create_batch!" do
    let!(:pepsq_records) { create_list(:priority_end_product_sync_queue, 10) }
    subject { PriorityEpSyncBatchProcess.create_batch!(pepsq_records) }

    before do
      subject
    end

    it "will create a new batch_process" do
      expect(subject.class).to be(PriorityEpSyncBatchProcess)
      expect(BatchProcess.all.count).to eq(1)
    end

    it "will set the batch_type of the new batch_process to 'PriorityEpSyncBatchProcess'" do
      expect(subject.batch_type).to eq(PriorityEpSyncBatchProcess.name)
    end

    it "will set the state of the new batch_process to 'PRE_PROCESSING'" do
      expect(subject.state).to eq(Constants.BATCH_PROCESS.pre_processing)
    end

    it "will set records_attempted of the new batch_process to the number of records batched" do
      expect(subject.records_attempted).to eq(pepsq_records.count)
    end

    it "will assign the newly created batch_process batch_id to all newly batched records" do
      all_pepsq_batch_ids = pepsq_records.map(&:batch_id)
      expect(all_pepsq_batch_ids).to all(eq(subject.batch_id))
    end

    it "will set the status of each newly batched record to 'PRE_PROCESSING'" do
      all_pepsq_statuses = pepsq_records.map(&:status)
      expect(all_pepsq_statuses).to all(eq(Constants.PRIORITY_EP_SYNC.pre_processing))
    end

    it "will set the last_batched_at Date/Time of each newly batched record to the current Date/Time" do
      all_pepsq_last_batched_at_times = pepsq_records.map(&:last_batched_at)
      expect(all_pepsq_last_batched_at_times).to all(eq(Time.zone.now))
    end
  end

  describe "#process_batch!" do
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

    let!(:batch_process) { PriorityEpSyncBatchProcess.create_batch!(pepsq_records) }

    subject { batch_process.process_batch! }

    context "when all batched records in the queue are able to sync successfully" do
      before do
        subject
        pepsq_records.each(&:reload)
      end
      it "each batched record in the queue will have a status of 'SYNCED' \n
           and the batch process will have a state of 'COMPLETED'" do
        all_pepsq_statuses = pepsq_records.pluck(:status)
        expect(all_pepsq_statuses).to all(eq(Constants.PRIORITY_EP_SYNC.synced))
        expect(batch_process.state).to eq(Constants.BATCH_PROCESS.completed)
      end

      it "the number of records_attempted for the batch process will match the number of PEPSQ records batched, \n
           the number of records_completed for the batch process will match the number of PEPSQ records synced, \n
           and the number of records_failed for the batch process will match the number of PEPSQ records not synced" do
        expect(batch_process.records_attempted).to eq(pepsq_records.count)
        all_synced_pepsq_records = pepsq_records.select { |record| record.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_completed).to eq(all_synced_pepsq_records.count)
        all_synced_pepsq_records = pepsq_records.reject { |record| record.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_failed).to eq(all_synced_pepsq_records.count)
      end
    end

    context "when one of the batched records fails because the synced_status and level_status_code do not match" do
      before do
        active_hlr_epe_w_cleared_vbms_ext_claim.vbms_ext_claim.update!(level_status_code: "CAN")
        allow(Rails.logger).to receive(:error)
        subject
        pepsq_records.each(&:reload)
      end

      it "all but ONE of the batched records will have a status of 'SYNCED'" do
        synced_status_pepsq_records = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        not_synced_status_pepsq_records = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(synced_status_pepsq_records.count).to eq(pepsq_records.count - not_synced_status_pepsq_records.count)
        expect(not_synced_status_pepsq_records.count).to eq(pepsq_records.count - synced_status_pepsq_records.count)
      end

      it "the failed batched record will have a status of 'ERROR' \n
          and the failed batched record will raise and log error" do
        pepsq_record_without_synced_status = pepsq_records.find { |r| r.status != Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_record_without_synced_status.status).to eq(Constants.PRIORITY_EP_SYNC.error)
        active_hlr_epe_w_cleared_vbms_ext_claim.reload
        expect(Rails.logger).to have_received(:error)
          .with("#<Caseflow::Error::PriorityEndProductSyncError: EPE ID: #{active_hlr_epe_w_cleared_vbms_ext_claim.id}"\
                ".  EPE synced_status of #{active_hlr_epe_w_cleared_vbms_ext_claim.synced_status} does not match the"\
                " VBMS_EXT_CLAIM level_status_code of"\
                " #{active_hlr_epe_w_cleared_vbms_ext_claim.vbms_ext_claim.level_status_code}.>")
      end

      it "the batch process will have a state of 'COMPLETED', \n
          the number of records_attempted for the batch process will match the number of PEPSQ records batched, \n
          the number of records_completed for the batch process will match the number of successfully synced records \n
          the number of records_failed for the batch process will match the number of errored records" do
        expect(batch_process.state).to eq(Constants.BATCH_PROCESS.completed)
        expect(batch_process.records_attempted).to eq(pepsq_records.count)
        synced_pepsq_records = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_completed).to eq(synced_pepsq_records.count)
        failed_sync_pepsq_records = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_failed).to eq(failed_sync_pepsq_records.count)
      end
    end

    context "when one of the batched records fails because there is no related End Product within Vbms_Ext_Claim" do
      before do
        active_hlr_epe_w_cleared_vbms_ext_claim.vbms_ext_claim.destroy!
        allow(Rails.logger).to receive(:error)
        subject
        pepsq_records.each(&:reload)
      end

      it "all but ONE of the batched records will have a status of 'SYNCED'" do
        synced_pepsq_records = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        not_synced_pepsq_records = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(synced_pepsq_records.count).to eq(pepsq_records.count - not_synced_pepsq_records.count)
        expect(not_synced_pepsq_records.count).to eq(pepsq_records.count - synced_pepsq_records.count)
      end

      it "the failed batched record will have a status of 'ERROR' \n
          and the failed batched record will raise and log error" do
        pepsq_record_without_synced_status = pepsq_records.find { |r| r.status != Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_record_without_synced_status.status).to eq(Constants.PRIORITY_EP_SYNC.error)
        expect(Rails.logger).to have_received(:error)
          .with("#<Caseflow::Error::PriorityEndProductSyncError: Claim ID:"\
                " #{active_hlr_epe_w_cleared_vbms_ext_claim.reference_id}"\
                " not In VBMS_EXT_CLAIM.>")
      end

      it "calling '.vbms_ext_claim' on the failed batched record's End Product Establishment will return nil" do
        pepsq_record_without_synced_status = pepsq_records.find { |r| r.status != Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_record_without_synced_status.end_product_establishment.vbms_ext_claim).to eq(nil)
      end

      it "the batch process will have a state of 'COMPLETED', \n
          the number of records_attempted for the batch process will match the number of PEPSQ records batched, \n
          the number of records_completed for the batch process will match the number of successfully synced records, \n
          and the number of records_failed for the batch process will match the number of errored records" do
        expect(batch_process.state).to eq(Constants.BATCH_PROCESS.completed)
        expect(batch_process.records_attempted).to eq(pepsq_records.count)
        synced_pepsq_records = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_completed).to eq(synced_pepsq_records.count)
        failed_sync_pepsq_records = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_failed).to eq(failed_sync_pepsq_records.count)
      end
    end

    context "when one of the batched records fails because the End Product does not exist in BGS" do
      before do
        epe = EndProductEstablishment.find active_hlr_epe_w_cleared_vbms_ext_claim.id
        Fakes::EndProductStore.cache_store.redis.del("end_product_records_test:#{epe.veteran_file_number}")
        allow(Rails.logger).to receive(:error)
        subject
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

      it "the failed batched record will have a status of 'ERROR' \n
          and the failed batched record will raise and log error" do
        pepsq_record_without_synced_status = pepsq_records.find { |r| r.status != Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_record_without_synced_status.status).to eq(Constants.PRIORITY_EP_SYNC.error)
        expect(Rails.logger).to have_received(:error)
          .with("#<EndProductEstablishment::EstablishedEndProductNotFound: "\
                "EndProductEstablishment::EstablishedEndProductNotFound>")
      end

      it "the batch process will have a state of 'COMPLETED' \n
          and the number of records_attempted for the batch process will match the number of PEPSQ records batched" do
        expect(batch_process.state).to eq(Constants.BATCH_PROCESS.completed)
        expect(batch_process.records_attempted).to eq(pepsq_records.count)
      end

      it "the number of records_completed for the batch process will match the number of successfully synced records \n
           and the number of records_failed for the batch process will match the number of errored records" do
        synced_pepsq_records = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_completed).to eq(synced_pepsq_records.count)
        failed_sync_pepsq_records = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_failed).to eq(failed_sync_pepsq_records.count)
      end
    end
  end
end
