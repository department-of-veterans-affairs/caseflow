# frozen_string_literal: true

##
# Class to validate that SQL queries return the same results as the corresponding Rails query.

class ValidateSqlQueries
  RAILS_EQUIV_PREFIX = "/* RAILS_EQUIV"
  POSTPROC_SQL_RESULT_PREFIX = "/* POSTPROC_SQL_RESULT"

  class << self
    def process(query_dir, output_dir)
      puts "Examining queries in directory: #{query_dir}"
      output_dir = File.expand_path(output_dir)
      FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)

      filenames = list_query_filenames(query_dir)
      puts "  Found #{filenames.size} #{'query'.pluralize(filenames.size)} in #{query_dir}"

      # Run queries in each file and save output
      puts "  Output files will be saved to '#{output_dir}'"
      filenames.each { |filename| run_queries_and_save_output(filename, output_dir) }

      nonequivalent_basenames = compare_output_files(output_dir)
      [filenames.size, nonequivalent_basenames]
    end

    def list_query_filenames(query_dir)
      Dir["#{query_dir}/*.sql"].sort
    end

    def run_queries_and_save_output(filename, output_dir)
      puts "  Processing '#{filename}' ..."
      basename = File.basename(filename, File.extname(filename))
      # Run the queries from the file and save each output to different files for comparison
      run_queries(**extract_queries(IO.read(filename))) do |result_key, result, _error|
        output_filename = "#{basename}.#{result_key}-out"
        puts "    Saving output to #{output_filename}"
        File.open("#{output_dir}/#{output_filename}", "w") { |file| file.puts result.to_s }
      end
    rescue ScriptError, StandardError => error
      warn "    !Skipping due to error when executing query: #{error.message.lines.first}"
    end

    def extract_queries(file_contents)
      parser = SqlQueryParser.new(file_contents)
      parser.extract_queries
      {
        rails_query: validate_rails_query(parser.rails_query),
        sql_query: validate_sql_query(parser.sql_query),
        rails_sql_postproc: validate_rails_query(parser.postprocess_cmds)
      }
    end

    def validate_rails_query(query)
      # To-do: filter query to make it as safe as possible
      query.strip
    end

    def validate_sql_query(query)
      # To-do: filter query to make it as safe as possible
      query.strip
    end

    def run_queries(rails_query:, sql_query:, rails_sql_postproc:)
      if rails_query.present?
        # Execute Rails query
        rails_result, rails_error = eval_rails_query(rails_query)
        yield("rb", rails_result, rails_error) if block_given?
        fail rails_error if rails_error

        # Execute SQL query
        sql_result, sql_error = eval_sql_query(sql_query, rails_sql_postproc)
        yield("sql", sql_result, sql_error) if block_given?
        fail sql_error if sql_error
      else
        warn "    !No Rails query found in the SQL -- skipping."
      end
    end

    def compare_output_files(output_dir)
      puts "Comparing query output files in #{output_dir} ..."
      Dir.chdir(output_dir) do
        diffs = Dir["*.rb-out"].sort.map do |rb_out_file|
          basename = File.basename(rb_out_file, File.extname(rb_out_file))
          sql_out_file = "#{basename}.sql-out"
          if File.exist?(sql_out_file)
            files_are_same = FileUtils.identical?(rb_out_file, sql_out_file)
            warn "  Different: #{rb_out_file} #{sql_out_file}" unless files_are_same
            basename unless files_are_same
          else
            warn "  No associated SQL output found for #{rb_out_file} "
            basename
          end
        end.compact
        diffs
      end
    end

    def eval_rails_query(query)
      # Default postprocessing to split results into separate lines
      query += "\n array_output.map{|r| r.to_s}.join('\n')" if query.include?("array_output")
      safely_eval_rails_query(query)
    end

    def eval_sql_query(query, postprocess_cmds)
      init_result, rescued_error = EvalEnvironment.wrap_in_rollback_transaction do
        ActiveRecord::Base.connection.execute(query)
      end

      # Default postprocessing commands to transform SQL results into reasonable output
      postprocess_cmds = "each_row.map{|r| r.to_s}.join('\n')" if postprocess_cmds.blank?
      result, rescued_error = safely_eval_rails_query("@result.#{postprocess_cmds}", init_result) unless rescued_error

      result ||= init_result || "(No SQL result)"
      [result, rescued_error]
    end

    def safely_eval_rails_query(query, init_result = nil)
      EvalEnvironment.new(init_result).eval_query_within_rollback_transaction(query)
    end
  end

  # Attempt to minimize exposure of environment when calling eval
  class EvalEnvironment
    def initialize(result)
      # @result is available for use in query when eval_query is called
      @result = result
    end

    def eval_query(query)
      binding.eval(query) # rubocop:disable Security/Eval
    end

    def eval_query_within_rollback_transaction(query)
      self.class.wrap_in_rollback_transaction { eval_query(query) }
    end

    def self.wrap_in_rollback_transaction
      # To-do: open read-only connection to database
      suppress_sql_logging do
        rescued_error = nil
        result = nil
        ActiveRecord::Base.transaction do
          result = yield if block_given?
        rescue ScriptError, StandardError => error
          result = "ERROR with query:\n#{error.message}\n\n#{error.backtrace.join("\n")}"
          rescued_error = error
        ensure
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
    attr_reader :rails_query, :sql_query, :postprocess_cmds

    def initialize(file_contents)
      @contents = file_contents
      @rails_query = ""
      @sql_query = ""
      @postprocess_cmds = ""
    end

    # To-do: Improve parsing of query
    # :reek:FeatureEnvy
    def extract_queries
      rails_equiv_mode = false
      postproc_mode = false
      @contents.each_line do |line|
        line.strip!
        if line.start_with?("*/")
          rails_equiv_mode = false
          postproc_mode = false
        elsif rails_equiv_mode || line.start_with?(RAILS_EQUIV_PREFIX)
          @rails_query += "\n" + line.sub(RAILS_EQUIV_PREFIX, "").strip
          rails_equiv_mode = true
        elsif postproc_mode || line.start_with?(POSTPROC_SQL_RESULT_PREFIX)
          @postprocess_cmds += "\n" + line.sub(POSTPROC_SQL_RESULT_PREFIX, "").strip
          postproc_mode = true
        else
          @sql_query += "\n" + line
        end
      end
    end
  end
end
