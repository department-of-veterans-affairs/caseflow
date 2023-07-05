# frozen_string_literal: true

describe PriorityEndProductSyncQueue, :postgres do

  let!(:end_product_establishment) do
    EndProductEstablishment.create(
      payee_code: "10",
      source_id: 1,
      source_type: "HigherLevelReview",
      veteran_file_number: 1
    )
  end

  let!(:pepsq) do
    PriorityEndProductSyncQueue.create(
      batch_id: nil,
      created_at: Time.zone.now,
      end_product_establishment_id: end_product_establishment.id,
      error_messages: [],
      last_batched_at: nil,
      status: "PRE_PROCESSING"
    )
  end

  context "#end_product_establishment" do
    it "will return the End Product Establishment object" do
      expect(pepsq.end_product_establishment).to eq(end_product_establishment)
    end
  end

  context "#status_processing!" do
    it "updates the PEPSQ record's status to 'PROCESSING'" do
      expect(pepsq.status).not_to eq("PROCESSING")
      pepsq.status_processing!
      expect(pepsq.status).to eq("PROCESSING")
    end
  end

  context "#status_sync!" do
    it "updates the PEPSQ record's status to 'SYNCED'" do
      expect(pepsq.status).not_to eq("SYNCED")
      pepsq.status_sync!
      expect(pepsq.status).to eq("SYNCED")
    end
  end

  context "#status_error!(error)" do
    it "updates the PEPSQ record's status to 'ERROR' and adds any error messages, along with batch_id, to array" do
      expect(pepsq.status).not_to eq("ERROR")
      expect(pepsq.error_messages).to eq([])

      uuid = SecureRandom.uuid
      pepsq.status_error!(["Error: EndProductEstablishmentNotFound - Batch ID: #{uuid} - Time: #{Time.zone.now}."])

      expect(pepsq.status).to eq("ERROR")
      expect(pepsq.error_messages).to eq(["Error: EndProductEstablishmentNotFound - Batch ID: #{uuid} - Time: #{Time.zone.now}."])
    end
  end

  context "#declare_record_stuck!" do
    let!(:stuck_pepsq) do
      PriorityEndProductSyncQueue.create(
        created_at: Time.zone.now,
        end_product_establishment_id: create(:end_product_establishment, :active_hlr).id,
        error_messages: ["error 1 - batch id 1", "error 2 - batch id 2", "error 3 - batch id 3"],
        last_batched_at: Time.zone.now + 1,
        status: "ERROR"
      )
    end

    it "updates the PEPSQ record's status to 'STUCK' and creates corresponding CaseflowStuckRecord record" do
      expect(stuck_pepsq.status).not_to eq("STUCK")
      expect(stuck_pepsq.error_messages.length).to eq(3)

      before_count = CaseflowStuckRecord.all.count

      stuck_pepsq.declare_record_stuck!

      expect(stuck_pepsq.status).to eq("STUCK")

      # new record added to CaseflowStuckRecord table
      expect(CaseflowStuckRecord.all.count).to eq(before_count + 1)

      # stuck_pepsq's error messages are transferred to the new CaseflowStuckRecord
      expect(CaseflowStuckRecord.last.error_messages).to eq(stuck_pepsq.error_messages)
    end
  end

end
