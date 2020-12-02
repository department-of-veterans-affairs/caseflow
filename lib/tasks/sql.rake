# frozen_string_literal: true

##
# Example usage:
#    # 1. Get cards from Metabase and save to cards.json
#    scripts/metabase_client.sh cards cards.json
#
#    # 2. Extract queries from cards.json into sql_queries
#    bundle exec rake 'sql:extract_queries_from[cards.json,sql_queries]'
#    bundle exec rake 'sql:validate[sql_queries,queries_output]'
#
#    # 3. After examining differences, clean up directories
#    rm -rf sql_queries/ queries_output/
#
#  To validate your own SQL, save your SQL in sql_queries then run
#     bundle exec rake 'sql:validate[sql_queries,queries_output]'

namespace :sql do
  VALIDATE_SQL_TRIGGER_STRING = "-- VALIDATE_SQL"

  desc "extract SQL queries from JSON file containing cards from Metabase"
  task :extract_queries_from, [:inputfile, :query_dir] => [:environment] do |_t, args|
    if args[:inputfile].nil? || args[:query_dir].nil?
      puts "Usage example: rake 'sql:extract_queries_from[cards.json,sql_queries]'"
      exit 3
    end
    FileUtils.mkdir_p(args[:query_dir]) unless File.directory?(args[:query_dir])

    json = File.read(args[:inputfile])
    cards = JSON.parse(json)
    filtered_cards = cards.select do |card|
      card["archived"] == false &&
        card["query_type"] == "native" &&
        card["dataset_query"]["native"]["query"]&.include?(VALIDATE_SQL_TRIGGER_STRING)
    end
    puts "Found #{filtered_cards.count} cards to be validated out of #{cards.count} cards total"

    filtered_cards.sort_by { |obj| [obj["database_id"], obj["id"]] }.each do |obj|
      creator_name = obj["creator"]["common_name"]
      puts "  Card #{obj['id']} by #{creator_name} (collection #{obj['collection']['id']}): '#{obj['name']}'"
      query_string = obj["dataset_query"]["native"]["query"]
      output_filename = "db#{obj['database_id'].to_s.rjust(2, '0')}_c#{obj['id'].to_s.rjust(4, '0')}.sql"
      puts "    Saving SQL to #{output_filename}"
      File.open("#{args[:query_dir]}/#{output_filename}", "w") { |file| file.puts query_string }
    end
  end

  desc "validate SQL queries against Rails queries"
  task :validate, [:query_dir, :output_dir] => [:environment] do |_t, args|
    if args[:query_dir].nil? || args[:output_dir].nil?
      puts "Usage example: rake 'sql:validate[sql_queries,queries_output]'"
      exit 3
    end

    sql_file_count, diff_basenames = ValidateSqlQueries.process(args[:query_dir], args[:output_dir])
    puts "Diffs: #{diff_basenames}"
    puts "#{diff_basenames.count} out of #{sql_file_count} queries are different!"
  end
end
