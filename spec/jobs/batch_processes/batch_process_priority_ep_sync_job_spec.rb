


describe BatchProcessPriorityEPSyncJobSpec, :postgres do
  # Testing the batch_priority_end_product_sync! method
  context 'Priority EP Sync Batch Creation Tests' do
    before(:each) do
      let(:seed) { Seeds::VbmsExtClaim.new }
      seed.seed!
      # put seed data into PEPSQ table
      batch = BatchProcess.batch_priority_end_product_sync!
    end

    it 'Checking if a new batch was created' do
      expect(batch).to eq(true)
    end

    it 'Checking if the created batch was populated correctly' do
      records = PriorityEndProductSyncQueue.where(batch_id: batch.batch_id)
      expect(records.length).to eq(100) #REPLACE with ENV when setup
    end
  end




  # Testing the process_priority_end_product_sync! method
  context 'Priority EP Sync Batch Processing Tests' do
    before(:each) do
      #call seed data
      #put the seed data into PEPSQ table
      batch = BatchProcess.batch_priority_end_product_sync!
      batch = BatchProces.process_priority_end_product_sync!(batch)
    end


    # Checking that the number of synced and failed records = the batch total
    it 'Ensuring the processing method attempted to sync every record' do
      expect(batch.records_completed +
             batch.records_failed).to eq(batch.records_attempted)
    end


    # Checking the number of synced records = the number the batch says synced
    it 'Ensuring the correct number of successful syncs' do
      synced_records = PriorityEndProductSyncQueue.where(batch_id: batch.id,
                                                         status: "SYNCED")

      expect(synced_records.length).to eq(batch.records_completed)
    end


    # Checking that the number of failed records = the number the batch says failed
    it 'Ensuring the correct number of failed syncs' do
      failed_records = PriorityEndProductSyncQueue.where(batch_id: batch.id,
                                                         status: "ERROR")

      expect(failed_records.length).to eq(batch.records_failed)
    end


    # Checking to make sure the EPE and VBMS tables are now synced for each record
    it 'Ensuring the records marked synced were synced corrected' do
      synced_records = PriorityEndProductSyncQueue.where(batch_id: batch.batch_id,
                                                         status: "SYNCED")
      correctly_synced = 0
      synced_records.each do |r|
        vbms_rec = VbmsExtClaim.find_by(CLAIM_ID: r.end_product_establishment.reference_id)
        if r.end_product_establishment.sync_status == vbms_rec.level_status_code
          correctly_synced+=1
        end
      end

      expect(correctly_synced).to eq(synced_records.length)
    end


    # Checking to make sure that when a record fails to synce
    # the processing method errors out the record correctly
    it 'Ensuring the a failed record is updated correctly' do
            # .and_raise(StandardError.new)

    end

    # Checking that a new record was created within the caseflow_stuck_recoreds
    # table, based off the record in priority_end_product_sync_queue that was
    # declared stuck.
    it 'Ensuring the processing method declares a stuck record correctly' do
      # Need a record in priority sync queue table with 3 errors +
      # a record with the priority sync queue ID in Caseflow stuck records table
      stuck_records = PriorityEndProductSyncQueue.where(batch_id: batch.id,
                                                        batch_type: "STUCK")
      found_records = 0
      stuck_records.each do |r|
        if CaseflowStuckRecord.find_by(stuck_record_id: r.id)
          found_records+=1
        end
      end
      expect(found_records).to eq(stuck_records.length)
    end

  end
end
