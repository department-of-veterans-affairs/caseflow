# This task now creates a log file with a name that includes the date and time that the task was run in the local time zone,
# and it appends the log output to the end of the file using the File.open block.
# The FileUtils.mkdir_p method is used to create the log directory if it doesn't already exist.

require 'fileutils'

namespace :war_room do
  desc "Sync duplicate end product claims and log output to file"
  task dupp_ep_claims_sync_status_update_can_clr: :environment do
    log_dir = File.join(Rails.root, 'log')
    FileUtils.mkdir_p(log_dir) unless File.directory?(log_dir)

    log_file = File.join(log_dir, "duplicateeptask_#{Time.zone.now.strftime('%Y-%m-%d_%H%M%S')}.log")
    File.open(log_file, 'a') do |f|
      f.puts "Duplicate End Product Claims Sync Status Update CAN CLR Task Log"
      f.puts "Timestamp: #{Time.zone.now}"
      f.puts "-" * 50

      WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.run(output: f)
    end
  end
end
