# frozen_string_literal: true

# bundle exec rails runner scripts/update_vacols_stmdtime_from_caseflow.rb

# Updates CORRES.STMDTIME for any veterans whose SFNOD was updated in VACOLS via the MPI person update controller

@update_count = 0

puts "TIME START: #{Time.zone.now}"
puts "Getting all successful MPI person update events that resulted in a VACOLS update"
# get all successful updates
successful_updates = MpiUpdatePersonEvent.where(update_type: :successful).to_a

# update_type :already_deceased_time_changed and :already_deceased share the same string, so filter
# the results if not an actual update to the record
already_deceased_time_changed =
  MpiUpdatePersonEvent.where(update_type: :already_deceased_time_changed)
    .filter { |obj| obj.info.include?("updated_deceased_time") }.to_a

# concat all updates into one array
all_updates = successful_updates.concat(already_deceased_time_changed)

puts "Found #{all_updates.count} MpiUpdatePersonEvents that resulted in VACOLS updates"

# map over each object to get hash of { veteran_pat=>completed_at } for each entry
# VacolsHelper required because VACOLS stores time as eastern time but with UTC as the time zone
update_mapping = all_updates.map do |obj|
  [obj.info["veteran_pat"], VacolsHelper.format_datetime_with_utc_timezone(obj.completed_at)]
end.to_h

puts "Filtering all MPI person update events that are older than the most recent change to the CORRES VACOLS record"
# compare current STMDTIME value and do not update if current value is newer than MpiUpdatePersonEvent creation time
updates_for_vacols = update_mapping.map do |update|
  # .find() errors if a CORRES record not found
  corres_record = VACOLS::Correspondent.find_by(stafkey: update[0])
  next if corres_record.nil?
  next update if corres_record.stmdtime.nil?

  next if corres_record.stmdtime.to_datetime >= update[1].to_datetime

  update
end.compact
puts "Found #{updates_for_vacols.count} VACOLS records with STMDTIME that requires updating"

# raw SQL to update CORRES records
query = <<-SQL
  update CORRES
  set STMDTIME = ?,
      STMDUSER = 'MPIBATCH'
  where STAFKEY = ?
SQL

# set database connection
conn = VACOLS::Correspondent.connection

puts "Starting VACOLS record updates"
# sanitize_sql_array is a private method on ActiveRecord::Base so use .send() to access it
# execute query to update record
updates_for_vacols.each do |update|
  @update_count += 1
  conn.execute(VACOLS::Correspondent.send(:sanitize_sql_array, [query, update[1], update[0]]))
end
puts "Finished VACOLS record updates; updated #{@update_count} records"
puts "TIME FINISHED: #{Time.zone.now}"
