# frozen_string_literal: true

namespace :sql do
  desc "validate SQL queries against Rails queries"
  task validate: :environment do
    puts "TODO: query Metabase queries"
    query_dir = "tmp/railsSqlComparison"
    puts "TODO: populate query_dir with relevant queries"
    output_dir = "tmp/query_results"
    diff_queries = ValidateSqlQueries.process(query_dir, output_dir)
    puts "Diffs: #{diff_queries.count}"
  end

  VALIDATE_SQL_TRIGGER_STRING = "-- VALIDATE_SQL"
  task parse_json: :environment do
    json = File.read("cards.json")
    objs = JSON.parse(json)
    puts objs.count
    objs = objs.select do |obj|
      [2, 3, 4].include?(obj["database_id"]) &&
        obj["query_type"] == "native" &&
        obj["dataset_query"]["native"]["query"]&.include?(VALIDATE_SQL_TRIGGER_STRING)
    end
    puts objs.count
    objs.sort_by { |obj| [obj["database_id"], obj["id"]] }.each do |obj|
      # pp obj.dataset_query.native.query
      puts "-----------------------"
      puts "-- DB #{obj['database_id']}: #{obj['id']} (#{obj['query_type']}): #{obj['name']}"
      query = obj["dataset_query"][obj["query_type"]]["query"]
      puts query.size
    end
  end

  task curl_metabase: :environment do
  end

  task auth_metabase: :environment do
  end
end
