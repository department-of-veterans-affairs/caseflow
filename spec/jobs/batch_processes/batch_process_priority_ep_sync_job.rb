


describe BatchProcessPriorityEPSyncJob, :postgres do
  context 'Priority EP Sync Batch Creation Tests' do
    before(:each) do
      # call seed data
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

  context 'Priority EP Sync Batch Processing Tests' do
    before(:each) do
      #call seed data
      #put the seed data into PEPSQ table
      batch = BatchProcess.batch_priority_end_product_sync!
      batch = BatchProces.process_priority_end_product_sync!(batch)
    end

    it 'Ensuring the processing method attempted to sync every record' do
      expect(batch.records_completed +
             batch.records_failed).to eq(batch.records_attempted)
    end

    it 'Ensuring the correct number of successful syncs' do
      synced_records = PriorityEndProductSyncQueue.where(batch_id: batch.id,
                                                         status: "SYNCED")

      expect(synced_records.length).to eq(batch.records_completed)
    end

    it 'Ensuring the correct number of failed syncs' do
      failed_records = PriorityEndProductSyncQueue.where(batch_id: batch.id,
                                                         status: "ERROR")

      expect(failed_records.length).to eq(batch.records_failed)
    end

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
