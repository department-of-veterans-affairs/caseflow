# frozen_string_literal: true

require "fileutils"

##
# Class to validate that SQL queries return the same results as the corresponding Rails query.

class ValidateSqlQueries

  # Attempt to minimize exposure of environment when calling eval
  class EvalEnvironment
    def initialize(result)
      @result = result
    end

    def eval_query(query)
      binding.eval(query)
    end
  end

  class << self
    def process(query_dir, output_dir)
      puts "Examining queries in directory: #{query_dir}"
      FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
      output_dir = File.expand_path(output_dir)

      Dir.chdir(query_dir)
      filebasenames = list_query_filebasenames.sort
      puts "Found #{filebasenames.size} #{'query'.pluralize(filebasenames.size)} in #{query_dir}: #{filebasenames}"

      run_queries_and_save_output(filebasenames, output_dir)
      Dir.chdir(output_dir)
      compare_output_files(output_dir)
    end

    def list_query_filebasenames
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

    def safely_eval_query(query)
      new_result = nil
      orig_log_level = ActiveRecord::Base.logger.level
      ActiveRecord::Base.logger.level = :warn
      ActiveRecord::Base.transaction do
        result = nil
        result = yield if block_given?
        new_result = EvalEnvironment.new(result).eval_query(query)
      rescue StandardError => error
        # puts error.inspect
        # puts error.backtrace
        # puts "^^^^^^^^^^^^^^^^^^^^^^^^^^^"
        new_result = "ERROR with query:\n#{query}\n--------\n#{error.message}\n#{error.backtrace.join("\n")}"
      ensure
        fail ActiveRecord::Rollback
      end
      ActiveRecord::Base.logger.level = orig_log_level
      new_result
    end

    def save_result(results, out_filename)
      File.open(out_filename, "w") { |file| file.puts results.to_s }
    end

    def compare_output_files(output_dir)
      puts "Comparing query output files in #{output_dir} ..."
      diffs = Dir["*.rb-out"].sort.map do |rb_out_file|
        basename = File.basename(rb_out_file, File.extname(rb_out_file))
        sql_out_file = "#{basename}.sql-out"
        if File.exist?(sql_out_file)
          puts "  Comparing #{rb_out_file} with #{sql_out_file}"
          basename unless FileUtils.identical?(rb_out_file, sql_out_file)
        else
          basename
        end
      end.compact
      diffs
    end

    ### Rails

    def run_rails_query(in_filename)
      query = read_rails_query_from_file(in_filename)
      # TODO: open read-only connection to database
      # conn = ActiveRecord::Base.connection
      result = safely_eval_query(query)
      result ||= "Some Rails result"
      # puts "      Result: #{result}"
      result
    end

    def read_rails_query_from_file(in_filename)
      contents = IO.read(in_filename)
      validate_sql_query(contents)
    end

    def validate_rails_query(query)
      # To-do: filter query to make it as safe as possible
      query.strip
    end

    ### SQL

    POST_SQL_PREFIX = "-- POST_SQL_RESULTS:"

    def run_sql_query(in_filename)
      query, postprocess_cmds = read_sql_query_from_file(in_filename)
      # TODO: open read-only connection to database
      result = safely_eval_query("@result.to_a.#{postprocess_cmds}") { ActiveRecord::Base.connection.execute(query) } unless postprocess_cmds.strip.empty?
      result ||= "Some SQL result"
      # puts "      Result: #{result}"
      result
    end

    def read_sql_query_from_file(in_filename)
      query = ""
      postprocess_cmds = ""
      File.open(in_filename).each_line do |line|
        line.strip!
        if line.start_with?(POST_SQL_PREFIX)
          postprocess_cmds += "\n" + line.sub(POST_SQL_PREFIX, "").strip
        else
          query += "\n" + line
        end
      end
      [validate_sql_query(query), postprocess_cmds]
    end

    def validate_sql_query(query)
      # To-do: filter query to make it as safe as possible
      query.strip
    end
  end
end
