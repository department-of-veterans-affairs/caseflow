# frozen_string_literal: true

require "parallel"

namespace :db do
  desc "Initializes MeetingType records for all classes that require them"
  task backfill_meeting_types: :environment do
    [Hearing, LegacyHearing, VirtualHearing].each do |hearing_class|
      hearing_class.find_in_batches(batch_size: 2500) do |hearing_batch|
        inserts = Parallel.map(hearing_batch, in_threads: 4) do |hear|
          {
            conferenceable_id: hear.id,
            conferenceable_type: hearing_class.to_s,
            service_name: "pexip"
          }
        end

        MeetingType.insert_all(inserts)
      end
    end

    puts(
      "\n\n==============\n" \
      "[SUCCESS] - All records have been successfully backfilled!\n" \
      "=============="
    )
  end
end
