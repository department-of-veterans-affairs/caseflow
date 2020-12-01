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
      binding.eval(query) # rubocop:disable Security/Eval
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

    def safely_eval_rails_query(query, init_result = nil)
      wrap_in_rollback_transaction do
        EvalEnvironment.new(init_result).eval_query(query)
      end
    end

    def wrap_in_rollback_transaction
      # TODO: open read-only connection to database
      suppress_sql_logging do
        result = nil
        ActiveRecord::Base.transaction do
          result = yield if block_given?        
        # Exception includes SyntaxError and StandardError
        rescue Exception => error # rubocop:disable Lint/RescueException
          # puts error.message
          # puts error.backtrace
          # puts "^^^^^^^^^^^^^^^^^^^^^^^^^^^"
          result = "ERROR with Rails query:\n#{query}\n--------\n#{error.message}\n#{error.backtrace.join("\n")}"
        ensure
          fail ActiveRecord::Rollback
        end
        result
      end
    end

    def suppress_sql_logging
      orig_log_level = ActiveRecord::Base.logger.level
      ActiveRecord::Base.logger.level = :warn
      result = yield
      ActiveRecord::Base.logger.level = orig_log_level
      result
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
      safely_eval_rails_query(query) || "Problem evaluating Rails: #{query}"
    end

    def read_rails_query_from_file(in_filename)
      contents = IO.read(in_filename)
      validate_rails_query(contents)
    end

    def validate_rails_query(query)
      # To-do: filter query to make it as safe as possible
      query.strip
    end

    ### SQL

    POSTPROC_SQL_RESULT_PREFIX = "-- POSTPROC_SQL_RESULT:"

    def run_sql_query(in_filename)
      query, postprocess_cmds = read_sql_query_from_file(in_filename)
      postprocess_cmds = 'each_row.map{|r| r.to_s}.join("\n")' if postprocess_cmds.blank?

      init_result = wrap_in_rollback_transaction { ActiveRecord::Base.connection.execute(query) }
      result = safely_eval_rails_query("@result.#{postprocess_cmds}", init_result)
      result ||= init_result || "Some SQL result"
      result
    end

    def read_sql_query_from_file(in_filename)
      query = ""
      postprocess_cmds = ""
      File.open(in_filename).each_line do |line|
        line.strip!
        if line.start_with?(POSTPROC_SQL_RESULT_PREFIX)
          postprocess_cmds += "\n" + line.sub(POSTPROC_SQL_RESULT_PREFIX, "").strip
        else
          query += "\n" + line
        end
      end
      [validate_sql_query(query), validate_rails_query(postprocess_cmds)]
    end

    def validate_sql_query(query)
      # To-do: filter query to make it as safe as possible
      # puts "SQL query: #{query.strip}"
      query.strip
    end
  end
end
