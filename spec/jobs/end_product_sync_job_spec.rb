require "rails_helper"

describe EndProductSyncJob do
  let!(:ramp_election) { create(:ramp_election, :established) }

  let!(:end_product_establishment) do
    create(:end_product_establishment,
           source: ramp_election,
           last_synced_at: nil,
           established_at: 4.days.ago)
  end

  context "#perform" do
    it "syncs the end product establishment" do
      EndProductSyncJob.perform_now(end_product_establishment.id)

      expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
      expect(end_product_establishment.reload.last_synced_at).to_not eq(nil)
    end
  end
end
