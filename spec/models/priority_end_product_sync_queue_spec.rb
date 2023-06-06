# frozen_string_literal: true

describe PriorityEndProductSyncQueue, :postgres do
  context "#end_product_establishment" do
    let!(:end_product_establishment) do
      EndProductEstablishment.create(
        id: 1,
        payee_code: "10",
        source_id: 1,
        source_type: "HigherLevelReview",
        veteran_file_number: 1
      )
    end
    let!(:priority_end_product_sync_queue) do
      PriorityEndProductSyncQueue.create(
        id: 1,
        batch_id: nil,
        created_at: Time.zone.now,
        end_product_establishment_id: end_product_establishment.id,
        error_messages: [],
        last_batched_at: nil,
        status: "PENDING"
      )
    end
    it "will return the End Product Establishment object" do
      expect(priority_end_product_sync_queue.end_product_establishment).to eq(end_product_establishment)
    end
  end
end
