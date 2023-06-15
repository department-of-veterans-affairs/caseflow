# frozen_string_literal: true

require_relative "../../../lib/helpers/sync_attributes_with_bgs"

namespace :remediations do
  desc "Sync veteran cached attributes with bgs record"
  task :update_veteran_cached_attributes, [:file_number] => :environment do |_task, args|
    SyncAttributesWithBGS::VeteranCacheUpdater.new.run_by_file_number(args[:file_number])
  end

  desc "sync person cached attributes with bgs record"
  task :update_person_cached_attributes, [:participant_id] => :environment do |_task, args|
    SyncAttributesWithBGS::PersonCacheUpdater.new.run_by_participant_id(args[:participant_id])
  end
end
