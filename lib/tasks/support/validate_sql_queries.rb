# frozen_string_literal: true

##
# Class to validate that SQL queries return the same results as the corresponding Rails query.

class ValidateSqlQueries
  class << self
    def process(query_dir, output_dir)
      puts "Examining queries in directory: #{query_dir}"
      output_dir = File.expand_path(output_dir)
      FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)

      filenames = list_query_filenames(query_dir)
      puts "  Found #{filenames.size} #{'query'.pluralize(filenames.size)} in #{query_dir}"

      puts "  Query execution output will be saved to '#{output_dir}'"
      filenames.each do |filename|
        run_queries_and_save_output(filename, output_dir)
      end

      compare_output_files(output_dir)
    end

    def list_query_filenames(query_dir)
      Dir["#{query_dir}/*.sql"].sort
    end

    def run_queries_and_save_output(filename, output_dir)
      puts "  Processing '#{filename}' ..."
      basename = File.basename(filename, File.extname(filename))
      queries = extract_queries(IO.read(filename))
      save_results = lambda do |result_key, result, _error|
        output_filename = "#{basename}.#{result_key}-out"
        puts "    Saving output to #{output_filename}"
        File.open("#{output_dir}/#{output_filename}", "w") { |file| file.puts result.to_s }
      end

      run_rails_query(**queries, &save_results) unless File.exist?("#{output_dir}/#{basename}.rb-out")

      # If Metabase's query results exists, then don't need to run the SQL query
      run_sql_query(**queries, &save_results) unless File.exist?("#{output_dir}/#{basename}.mb-out")
    rescue ScriptError, StandardError => error
      warn "    !Skipping due to error when executing query: #{error.message.lines.first}"
    end

    def extract_queries(file_contents)
      parser = SqlQueryParser.new(file_contents)
      {
        rails_query: declaw_rails_query(parser.rails_query),
        sql_query: declaw_sql_query(parser.contents), # treat entire file as SQL
        rails_sql_postproc: declaw_rails_query(parser.postprocess_cmds),
        db_connection_string: declaw_rails_query(parser.db_connection)
      }
    end

    def declaw_rails_query(query)
      # To-do: filter query to make it as safe as possible
      query.strip unless query.blank?
    end

    def declaw_sql_query(query)
      # To-do: filter query to make it as safe as possible
      query.strip
    end

    def run_rails_query(rails_query:, **_other_keys)
      fail "No Rails query found in the SQL!" if rails_query.blank?

      rails_result, rails_error = eval_rails_query(rails_query)
      yield("rb", rails_result, rails_error) if block_given?
      fail rails_error if rails_error
    end

    # :reek:LongParameterList
    def run_sql_query(sql_query:, rails_sql_postproc: "", db_connection_string: nil, **_other_keys)
      sql_result, sql_error = eval_sql_query(sql_query, rails_sql_postproc, db_connection_string)
      yield("sql", sql_result, sql_error) if block_given?
      fail sql_error if sql_error
    end

    def compare_output_files(output_dir)
      Dir.chdir(output_dir) do
        rb_out_files = Dir["*.rb-out"].sort
        puts "Comparing query output files in #{output_dir} for #{rb_out_files.count} files..."

        diffs = rb_out_files.map do |rb_out_file|
          basename = File.basename(rb_out_file, File.extname(rb_out_file))
          sql_out_file = ["#{basename}.mb-out", "#{basename}.sql-out"].find { |out_file| File.exist?(out_file) }

          unless sql_out_file
            warn "  No associated SQL output found for #{rb_out_file}"
            next basename
          end

          puts "  Comparing: #{rb_out_file} and #{sql_out_file}"
          unless files_are_same?(rb_out_file, sql_out_file)
            warn "    Results don't match: diff #{rb_out_file} #{sql_out_file}"
            next basename
          end

          nil
        end.compact
        diffs
      end
    end

    # When comparing Metabase output, Metabase returns Date fields with a time component --
    # see https://github.com/metabase/metabase/issues/5859
    # So the SQL query should convert date columns to strings for comparison.
    def files_are_same?(rb_out_file, out_file)
      FileUtils.identical?(rb_out_file, out_file)
    end

    MAP_TO_STRING = "map{|r| r.map(&:inspect).join(',')}.join('\n')"

    def eval_rails_query(query)
      # Use default postprocessing to split results into separate lines if "array_output" appears in query
      query += "\n array_output.#{MAP_TO_STRING}" if query.include?("array_output")
      safely_eval_rails_query(query)
    end

    def eval_sql_query(query, postprocess_cmds, db_connection_string = nil)
      init_result, rescued_error = EvalEnvironment.wrap_in_rollback_transaction do
        conn = db_connection(db_connection_string)
        query = revise_vacols_query(query) if db_connection_string.present? && db_connection_string.include?("VACOLS::")
        conn.exec_query(query)
      end

      # Default postprocessing commands to transform SQL results into reasonable output
      postprocess_cmds = "rows.#{MAP_TO_STRING}" if postprocess_cmds.blank?
      result, rescued_error = safely_eval_rails_query("@result.#{postprocess_cmds}", init_result) unless rescued_error

      result ||= init_result || "(No SQL result)"
      [result, rescued_error]
    end

    def db_connection(db_connection_string)
      return ActiveRecord::Base.connection if db_connection_string.blank?

      db_connection_string.constantize.connection
    end

    # Currently in Metabase, we query Redshift for VACOLS data, so we have to prefix VACOLS tables with "VACOLS.".
    # We have no connection to Redshift from the Caseflow application (where the Rails query is running),
    # hence we can't use the query as it.
    # This method removes that prefix since we have a direct connection to VACOLS in the Rails environment.
    def revise_vacols_query(query)
      query.gsub(/VACOLS\./i, "")
    end

    def safely_eval_rails_query(query, init_result = nil)
      EvalEnvironment.new(init_result).eval_query_within_rollback_transaction(query)
    end
  end

  # Attempt to minimize exposure of environment when calling eval
  class EvalEnvironment
    def initialize(result)
      # @result is available for use in the query when eval_query is called
      @result = result
    end

    def eval_query(query)
      # binding.eval limits the variables accessible to the query
      binding.eval(query) # rubocop:disable Security/Eval
    end

    def eval_query_within_rollback_transaction(query)
      self.class.wrap_in_rollback_transaction { eval_query(query) }
    end

    def self.wrap_in_rollback_transaction
      # Ideally, would like to open a read-only connection to the database
      # but using rollbacks for simplicity
      suppress_sql_logging do
        rescued_error = nil
        result = nil
        ActiveRecord::Base.transaction do
          result = yield if block_given?
        rescue ScriptError, StandardError => error
          result = "ERROR with query:\n#{error.message}\n\n#{error.backtrace.join("\n")}"
          rescued_error = error
        ensure
          # Always rollback the transaction so that query has no side-effect on the database
          fail ActiveRecord::Rollback
        end

        [result, rescued_error]
      end
    end

    def self.suppress_sql_logging
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
  end

  class SqlQueryParser
    attr_reader :contents

    def initialize(file_contents)
      @contents = file_contents
    end

    # identifies block of Rails code that is equivalent to the SQL query
    RAILS_EQUIV_PREFIX = "RAILS_EQUIV"

    def rails_query
      extract_block_contents(RAILS_EQUIV_PREFIX)
    end

    # identifies block of Rails code to postprocess SQL query results
    POSTPROC_SQL_RESULT_PREFIX = "POSTPROC_SQL_RESULT"

    def postprocess_cmds
      extract_block_contents(POSTPROC_SQL_RESULT_PREFIX)
    end

    # identifies the class on which to call `.connection` to execute the SQL query
    DATABASE_CONNECTION = "-- SQL_DB_CONNECTION:"

    # :reek:FeatureEnvy
    def db_connection
      @contents.each_line do |line|
        return line.sub(DATABASE_CONNECTION, "").strip if line.strip.start_with?(DATABASE_CONNECTION)
      end

      nil
    end

    private

    # :reek:FeatureEnvy
    def extract_block_contents(block_keyword)
      block_prefix = "/* #{block_keyword}"

      block_contents = ""
      in_block = false
      @contents.each_line do |line|
        line.strip!

        return block_contents if in_block && line.start_with?("*/")

        if in_block
          block_contents += "\n" + line
        elsif line.start_with?(block_prefix)
          block_contents += "\n" + line.sub(block_prefix, "").strip
          in_block = true
        end
      end

      fail "Expecting '*/' to end #{block_keyword} block" if in_block
    end
  end
end
