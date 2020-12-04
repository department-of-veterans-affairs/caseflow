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
#    # Shortcut: Both of Steps 1 and 2 can be performed by running a single command:
#    scripts/metabase_client.sh downloadAndValidate
#
#    # 3. After examining differences, clean up directories
#    rm -rf sql_queries/ queries_output/
#
#  To validate your own SQL, save your SQL in sql_queries then run
#     bundle exec rake 'sql:validate[sql_queries,queries_output]'
#
#  See reports/sql_queries/README.md for more specific instructions.

namespace :sql do
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
        card["dataset_query"]["native"]["query"]&.include?(ValidateSqlQueries::SqlQueryParser::RAILS_EQUIV_PREFIX)
    end
    puts "Found #{filtered_cards.count} cards to be validated out of #{cards.count} cards total"
    puts "Metabase SQL queries will be saved to '#{File.expand_path(args[:query_dir])}'"

    filtered_cards.sort_by { |obj| [obj["database_id"], obj["id"]] }.each do |obj|
      creator_name = obj["creator"]["common_name"]
      puts "  Card/Question #{obj['id']} by #{creator_name} (collection #{obj['collection']['id']}): '#{obj['name']}'"
      query_string = obj["dataset_query"]["native"]["query"]
      output_filename = "db#{obj['database_id'].to_s.rjust(2, '0')}_c#{obj['id'].to_s.rjust(4, '0')}.sql"
      puts "    Saving SQL to #{output_filename}"
      File.open("#{args[:query_dir]}/#{output_filename}", "w") { |file| file.puts query_string }
    end
  end

  desc "validate SQL queries against Rails queries"
  task :validate, [:query_dir, :output_dir] => [:environment] do |_t, args|
    if args[:query_dir].nil? || args[:output_dir].nil?
      puts "Usage example: rake 'sql:validate[reports/sql_queries,reports/queries_output]'"
      exit 3
    end

    sql_file_count, diff_basenames = ValidateSqlQueries.process(args[:query_dir], args[:output_dir])
    puts "Queries with different output: #{diff_basenames}"
    puts "SUMMARY: #{diff_basenames.count} out of #{sql_file_count} queries are different."
  end

  desc "validate a single SQL query file"
  task :validate_file, [:sql_filename, :output_dir] => [:environment] do |_t, args|
    if args[:sql_filename].nil? || args[:output_dir].nil?
      puts "Usage example: rake 'sql:validate_file[for_testing.sql,tmp]'"
      exit 3
    end

    sql_filename = args[:sql_filename]
    output_dir = args[:output_dir]
    ValidateSqlQueries.run_queries_and_save_output(sql_filename, output_dir)

    basename = File.basename(sql_filename, File.extname(sql_filename))
    rb_out_file = "#{output_dir}/#{basename}.rb-out"
    sql_out_file = "#{output_dir}/#{basename}.sql-out"
    puts "Comparing query output files: #{rb_out_file} and #{sql_out_file}"
    diff = if File.exist?(sql_out_file)
             files_are_same = FileUtils.identical?(rb_out_file, sql_out_file)
             warn "  Different: #{rb_out_file} #{sql_out_file}" unless files_are_same
             basename unless files_are_same
           else
             warn "  No associated SQL output found for #{rb_out_file} "
             basename
           end
    puts "Output is the same -- Hooray!" if diff.nil?
  end
end
