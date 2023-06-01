# frozen_string_literal: true

describe "remediations/sync_attributes_with_bgs" do
  include_context "rake"
  let(:args) { "44556677" }

  it "calls SyncAttributesWithBGS::VeteranCacheUpdater.run_by_file_number" do
    expect(SyncAttributesWithBGS::VeteranCacheUpdater).to receive(:run_by_file_number).with(args)
    Rake::Task["remediations:update_veteran_cached_attributes"].invoke(*args)
  end
end

describe "remediations:update_person_cached_attributes" do
  let(:args) { "987654" }

  it "calls SyncAttributesWithBGS::PersonCacheUpdater.run_by_participant_id" do
    expect(SyncAttributesWithBGS::PersonCacheUpdater).to receive(:run_by_participant_id).with(args)
    Rake::Task["remediations:update_person_cached_attributes"].invoke(*args)
  end
end
