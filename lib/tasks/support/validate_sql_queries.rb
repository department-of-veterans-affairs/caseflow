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
      filenames = list_query_filenames
      puts "  Found #{filenames.size} #{'query'.pluralize(filenames.size)} in #{query_dir}: #{filenames}"

      run_queries_and_save_output(filenames, output_dir)
      Dir.chdir(output_dir)
      compare_output_files(output_dir)
    end

    def list_query_filenames
      Dir["*.sql"].sort
    end

    def run_queries_and_save_output(filenames, output_dir)
      puts "  Output files will be saved to '#{output_dir}'"
      filenames.each do |filename|
        puts "  Processing '#{filename}'..."
        rails_query, sql_query, postprocess_cmds = read_queries_from_file(filename)
        # puts "== #{rails_query} \n=== #{sql_query}\n==== #{postprocess_cmds}"
        if rails_query.present?
          basename = File.basename(filename, File.extname(filename))

          output_filename = "#{output_dir}/#{basename}.rb-out"
          puts "    Executing Rails query and saving output to #{basename}.rb-out"
          result, rescued_error = run_rails_query(rails_query)
          save_result(result, output_filename)
          fail rescued_error if rescued_error

          output_filename = "#{output_dir}/#{basename}.sql-out"
          puts "    Executing SQL query and saving output to #{basename}.sql-out"
          result, rescued_error = run_sql_query(sql_query, postprocess_cmds)
          save_result(result, output_filename)
          fail rescued_error if rescued_error
        end
      rescue ScriptError, StandardError => error
        puts "! Skipping due to error when executing query (see #{output_filename}): #{error.message.lines.first}"
        # puts error.backtrace
        # puts "^^^^^^^^^^^^^^^^^^^^^^^^^^^"
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
        rescued_error = nil
        result = nil
        ActiveRecord::Base.transaction do
          result = yield if block_given?
        rescue ScriptError, StandardError => error
          # puts error.message
          # puts error.backtrace
          # puts "    ^^^^^^^^^^^^^^^^^^^^^^^^^^^"
          result = "ERROR with query:\n#{error.message}\n\n#{error.backtrace.join("\n")}"
          rescued_error = error
        ensure
          fail ActiveRecord::Rollback
        end

        # Could not reraise the error within rescue block above, so reraising it here
        # fail rescued_error if rescued_error

        [result, rescued_error]
      end
    end

    def suppress_sql_logging
      orig_log_level = ActiveRecord::Base.logger.level
      result = nil
      begin
        ActiveRecord::Base.logger.level = :warn
        result = yield
      ensure
        ActiveRecord::Base.logger.level = orig_log_level
      end
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

    def run_rails_query(query)
      safely_eval_rails_query(query)
    end

    ### SQL

    def run_sql_query(query, postprocess_cmds)
      postprocess_cmds = 'each_row.map{|r| r.to_s}.join("\n")' if postprocess_cmds.blank?

      init_result, rescued_error = wrap_in_rollback_transaction { ActiveRecord::Base.connection.execute(query) }
      result, rescued_error = safely_eval_rails_query("@result.#{postprocess_cmds}", init_result) unless rescued_error
      result ||= init_result || "(No SQL result)"
      [result, rescued_error]
    end

    RAILS_EQUIV_PREFIX = "-- RAILS_EQUIV:"
    POSTPROC_SQL_RESULT_PREFIX = "-- POSTPROC_SQL_RESULT:"

    def read_queries_from_file(in_filename)
      rails_query = ""
      sql_query = ""
      postprocess_cmds = ""
      File.open(in_filename).each_line do |line|
        line.strip!
        if line.start_with?(RAILS_EQUIV_PREFIX)
          rails_query += "\n" + line.sub(RAILS_EQUIV_PREFIX, "").strip
        elsif line.start_with?(POSTPROC_SQL_RESULT_PREFIX)
          postprocess_cmds += "\n" + line.sub(POSTPROC_SQL_RESULT_PREFIX, "").strip
        else
          sql_query += "\n" + line
        end
      end
      [validate_rails_query(rails_query), validate_sql_query(sql_query), validate_rails_query(postprocess_cmds)]
    end

    def validate_rails_query(query)
      # To-do: filter query to make it as safe as possible
      query.strip
    end

    def validate_sql_query(query)
      # To-do: filter query to make it as safe as possible
      # puts "SQL query: #{query.strip}"
      query.strip
    end
  end
end
