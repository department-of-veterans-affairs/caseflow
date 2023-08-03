# frozen_string_literal: true

describe "remediations/sync_attributes_with_bgs" do
  include_context "rake"
  describe "remediations:update_veteran_cached_attributes" do
    let(:args) { "44556677" }
    let(:instance) { SyncAttributesWithBGS::VeteranCacheUpdater.new }

    it "calls SyncAttributesWithBGS::VeteranCacheUpdater.run_by_file_number" do
      expect(SyncAttributesWithBGS::VeteranCacheUpdater).to receive(:new).and_return(instance)
      expect(instance).to receive(:run_by_file_number).with(args)
      Rake::Task["remediations:update_veteran_cached_attributes"].invoke(*args)
    end
  end

  describe "remediations:update_person_cached_attributes" do
    let(:args) { "987654" }
    let(:instance) { SyncAttributesWithBGS::PersonCacheUpdater.new }

    it "calls SyncAttributesWithBGS::PersonCacheUpdater.run_by_participant_id" do
      expect(SyncAttributesWithBGS::PersonCacheUpdater).to receive(:new).and_return(instance)
      expect(instance).to receive(:run_by_participant_id).with(args)
      Rake::Task["remediations:update_person_cached_attributes"].invoke(*args)
    end
  end
end
