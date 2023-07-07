# frozen_string_literal: true

require "./app/models/batch_processes/batch_process_priority_ep_sync.rb"

describe BatchProcessPriorityEpSync, :postgres do
  before do
    Timecop.freeze(Time.utc(2022, 1, 1, 12, 0, 0))
  end
  describe ".find_records" do
    let!(:pepsq_records) { create_list(:priority_end_product_sync_queue, BatchProcess::BATCH_LIMIT + 1) }
    context "when priority end product sync queue has 1 more record than the BATCH_LIMIT" do
      it "an array of all but one of the PriorityEndProductSyncQueue records are returned" do
        # number of records in queue should equal size of BATCH_LIMIT + 1
        expect(PriorityEndProductSyncQueue.count).to eq(BatchProcess::BATCH_LIMIT + 1)
        # Records in queue should match exactly pepsq_records
        expect(PriorityEndProductSyncQueue.all).to eq(pepsq_records)
        # the number of returned PEPSQ records should match the BATCH_LIMIT
        expect(BatchProcessPriorityEpSync.find_records.count).to eq(BatchProcess::BATCH_LIMIT)
      end
    end
    context "when all priority end product sync queue records are batched" do
      it "an empty array is returned" do
        BatchProcessPriorityEpSync.create_batch!(pepsq_records)
        expect(BatchProcessPriorityEpSync.find_records).to eq([])
      end
    end
  end

  describe ".create_batch!" do
    let!(:pepsq_records) { create_list(:priority_end_product_sync_queue, 10) }
    subject! { BatchProcessPriorityEpSync.create_batch!(pepsq_records) }
    it "will create a new batch_process" do
      expect(BatchProcess.all.count).to eq(1)
      expect(subject).to eq(BatchProcess.first)
      expect(subject.batch_type).to eq(BatchProcessPriorityEpSync.name)
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
    let!(:veteran) { create(:veteran) }
    let!(:vbms_ext_claims) { create_list(:vbms_ext_claim, 10, :cleared, claimant_person_id: veteran.participant_id) }
    let!(:end_product_establishments) do
      vbms_ext_claim_ids = vbms_ext_claims.map(&:claim_id).first(10)
      epes = create_list(:end_product_establishment, 10, :cleared, veteran_file_number: veteran.file_number)
      epes.each_with_index do |record, index|
        record.update_attribute(:reference_id, vbms_ext_claim_ids[index].to_s)
      end
    end
    let(:pepsq_records) do
      create_list(:priority_end_product_sync_queue, 10) do |record, index|
        record.update_attribute(:end_product_establishment_id, end_product_establishments[index].id)
      end
    end
    let!(:batch_process) { BatchProcessPriorityEpSync.create_batch!(pepsq_records) }
    subject { batch_process }
    context "when all batched records in the queue are able to sync successfully" do
      before do
        subject.process_batch!
        subject.reload
      end
      it "each batched record in the queue will have a status of 'SYNCED'" do
        pepsq_records.each(&:reload)
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
        pepsq_records.each(&:reload)
        all_synced_pepsq_records = pepsq_records.select { |record| record.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_completed).to eq(all_synced_pepsq_records.count)
      end
      it "the number of records_failed for the batch process will match the number of PEPSQ records not synced" do
        pepsq_records.each(&:reload)
        all_synced_pepsq_records = pepsq_records.reject { |record| record.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(batch_process.records_failed).to eq(all_synced_pepsq_records.count)
      end
    end

    context "when one of the batched records fails because the End Product Establishment synced_status and the Vbms_Ext_Claim level_status_code do not match" do
      before do
        vbms_ext_claims.last.update(level_status_code: 'CAN')
        allow(Rails.logger).to receive(:error)
        subject.process_batch!
        subject.reload
        pepsq_records.each(&:reload)
      end
      it "all but ONE of the batched records will have a status of 'SYNCED'" do
        pepsq_records_with_synced_status = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        pepsq_records_without_synced_status = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_records_with_synced_status.count).to eq(pepsq_records.count - pepsq_records_without_synced_status.count)
        expect(pepsq_records_without_synced_status.count).to eq(1)
      end
      it "the failed batched record will have a status of 'ERROR'" do
        pepsq_record_without_synced_status = pepsq_records.find { |r| r.status != Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_record_without_synced_status.status).to eq(Constants.PRIORITY_EP_SYNC.error)
      end
      it "the failed batched record will raise and log error: 'Caseflow::Error::PriorityEndProductSyncError: EPE synced_status does not match VBMS'" do
        expect(Rails.logger).to have_received(:error).with("#<Caseflow::Error::PriorityEndProductSyncError: EPE synced_status does not match VBMS.>")
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
        vbms_ext_claims.pop
        vbms_ext_claims.last.destroy
        allow(Rails.logger).to receive(:error)
        subject.process_batch!
        subject.reload
        pepsq_records.each(&:reload)
      end
      it "all but ONE of the batched records will have a status of 'SYNCED'" do
        pepsq_records_with_synced_status = pepsq_records.select { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        pepsq_records_without_synced_status = pepsq_records.reject { |r| r.status == Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_records_with_synced_status.count).to eq(vbms_ext_claims.count)
        expect(pepsq_records_without_synced_status.count).to eq(1)
      end
      it "the failed batched record will have a status of 'ERROR'" do
        pepsq_record_without_synced_status = pepsq_records.find { |r| r.status != Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_record_without_synced_status.status).to eq(Constants.PRIORITY_EP_SYNC.error)
      end
      it "calling '.vbms_ext_claim' on the failed batched record's End Product Establishment will return nil" do
        pepsq_record_without_synced_status = pepsq_records.find { |r| r.status != Constants.PRIORITY_EP_SYNC.synced }
        expect(pepsq_record_without_synced_status.end_product_establishment.vbms_ext_claim).to eq(nil)
      end
      it "the failed batched record will raise and log error: 'Caseflow::Error::PriorityEndProductSyncError: Claim Not In VBMS_EXT_CLAIM'" do
        expect(Rails.logger).to have_received(:error).with("#<Caseflow::Error::PriorityEndProductSyncError: Claim Not In VBMS_EXT_CLAIM.>")
      end
    end
  end
end
