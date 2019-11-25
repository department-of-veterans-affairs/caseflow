# frozen_string_literal: true

describe EndProductSyncJob, :postgres do
  let!(:ramp_election) { create(:ramp_election, :established) }

  let!(:end_product_establishment) do
    create(:end_product_establishment,
           source: ramp_election,
           last_synced_at: nil,
           established_at: 4.days.ago)
  end

  let(:bgs_error) do
    BGS::ShareError.new("More EPs more problems")
  end

  context "#perform" do
    it "syncs the end product establishment" do
      EndProductSyncJob.perform_now(end_product_establishment.id)

      expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
      expect(end_product_establishment.reload.last_synced_at).to_not eq(nil)
    end
  end

  it "saves Exception messages and logs error" do
    allow(Raven).to receive(:capture_exception) { @raven_called = true }
    allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_raise(bgs_error)

    EndProductSyncJob.perform_now(end_product_establishment.id)

    expect(@raven_called).to eq(true)
  end
end
