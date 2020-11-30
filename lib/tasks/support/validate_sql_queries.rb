# frozen_string_literal: true

class ValidateSqlQueries
  class << self
    def process(query_dir)
      puts "Examining queries in directory: #{query_dir}"
      filebasenames = list_query_filebasenames(query_dir).sort
      puts "Found #{filebasenames.size} #{'query'.pluralize(filebasenames.size)} in #{query_dir}: #{filebasenames}"
      output_dir = "query_results"
      Dir.mkdir(output_dir) unless File.directory?(output_dir)
      run_queries_and_save_output(filebasenames, output_dir)
      compare_output_files(output_dir)
    end

    def list_query_filebasenames(directory)
      Dir.chdir(directory)
      rails_filebasenames = Dir["*.rb"].map { |fn| File.basename(fn, File.extname(fn)) }
      sql_filebasenames = Dir["*.sql"].map { |fn| File.basename(fn, File.extname(fn)) }
      rails_filebasenames & sql_filebasenames
    end

    def run_queries_and_save_output(filebasenames, output_dir)
      filebasenames.each do |basename|
        puts "  Processing '#{basename}'..."
        puts "    Executing Rails query in #{basename}.rb and saving results"
        run_rails_query("#{basename}.rb").tap { |result| save_result(result, "#{output_dir}/#{basename}.rb-out") }
        puts "    Executing SQL query in #{basename}.sql and saving results"
        run_sql_query("#{basename}.sql").tap { |result| save_result(result, "#{output_dir}/#{basename}.sql-out") }
      rescue StandardError => error
        puts error.inspect
        puts error.backtrace
        puts "^^^^^^^^^^^^^^^^^^^^^^^^^^^"
      end
    end

    def save_result(results, out_filename)
      File.open(out_filename, "w") { |file| file.puts results.to_s }
    end

    def compare_output_files(output_dir)
      puts "Comparing query output files in #{output_dir} ..."
      Dir.chdir(output_dir)
      diffs = Dir["*.rb-out"].sort.map do |rb_out_file|
        basename = File.basename(rb_out_file, File.extname(rb_out_file))
        sql_out_file = "#{basename}.sql-out"
        puts "Comparing #{rb_out_file} with #{sql_out_file}"
        basename unless FileUtils.identical?(rb_out_file, sql_out_file)
      end.compact
      diffs
    end

    ### Rails

    def run_rails_query(in_filename)
      query = IO.read(in_filename) { |contents| validate_sql_query(contents) }
      # TODO: open read-only connection to database
      # conn = ActiveRecord::Base.connection
      result = eval(query)
      result ||= "Some Rails result"
      puts "      Result: #{result}"
      result
    end

    def validate_rails_query(query)
      # TODO
      puts "      Rails query: #{query}"
      query
    end

    ### SQL

    POST_SQL_PREFIX = "-- POST_SQL_RESULTS:"

    def run_sql_query(in_filename)
      query = "" # = IO.read(in_filename) {|query| validate_sql_query(query)}
      postprocess_cmds = ""
      File.open(in_filename).each_line do |line|
        line.strip!
        if line.starts_with?(POST_SQL_PREFIX)
          postprocess_cmds += "\n" + line.sub(POST_SQL_PREFIX, "").strip
        else
          query += "\n" + line
        end
      end
      # TODO: open read-only connection to database
      conn = ActiveRecord::Base.connection
      result = conn.execute(query)
      result = eval(postprocess_cmds) unless postprocess_cmds.strip.empty?
      result ||= "Some SQL result"
      puts "      Result: #{result}"
      result
    end

    def validate_sql_query(query)
      # TODO
      puts "      SQL query: #{query}"
      query
    end
  end
end
