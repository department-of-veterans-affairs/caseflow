# frozen_string_literal: true

require "tasks/support/validate_sql_queries.rb"

describe "sql", :postgres do
  include_context "rake"

  describe "sql:validate" do
    # Same as: bundle exec rake 'sql:validate[reports/sql_queries,reports/queries_output]'
    let(:args) { ["reports/sql_queries", "reports/queries_output"] }

    before do
      FileUtils.rm_rf("reports/queries_output")
    end

    subject do
      Rake::Task["sql:validate"].reenable
      Rake::Task["sql:validate"].invoke(*args)
    end

    context "using queries in reports/sql_queries" do
      it "completes validation with possible errors noted in console" do
        expect { subject }.to output(/SUMMARY: [0-9]* differenc/).to_stdout
      end
    end
  end

  describe "ValidateSqlQueries.extract_queries" do
    let(:file_contents) do
      <<~CONTENTS
        -- Total appeal counts in Caseflow
        /* RAILS_EQUIV
          [Appeal.count, LegacyAppeal.count]
        */

        -- SQL_DB_CONNECTION: Appeal

        WITH
          ama_appeals AS (SELECT * FROM appeals),
          leg_appeals AS (SELECT * FROM legacy_appeals)
        SELECT COUNT(*) FROM ama_appeals
        UNION ALL
        SELECT COUNT(*) FROM leg_appeals

        /* POSTPROC_SQL_RESULT
        to_a.map do |r|
          r["count"]
        end
        */
      CONTENTS
    end
    it "extract queries from file_contents string" do
      queries_hash = ValidateSqlQueries.extract_queries(file_contents)
      expected_rails_query = <<~RAILS_QUERY
        [Appeal.count, LegacyAppeal.count]
      RAILS_QUERY
      expect(queries_hash[:rails_query]).to eql expected_rails_query.chomp
      sql_rails_query = <<~SQL_QUERY
        WITH
          ama_appeals AS (SELECT * FROM appeals),
          leg_appeals AS (SELECT * FROM legacy_appeals)
        SELECT COUNT(*) FROM ama_appeals
        UNION ALL
        SELECT COUNT(*) FROM leg_appeals
      SQL_QUERY
      expect(queries_hash[:sql_query]).to include sql_rails_query
      expected_rails_sql_postproc = <<~RAILS_QUERY
        to_a.map do |r|
          r["count"]
        end
      RAILS_QUERY
      expect(queries_hash[:rails_sql_postproc]).to eql expected_rails_sql_postproc.lines.map(&:strip).join("\n").chomp
      expect(queries_hash[:db_connection_string]).to eql "Appeal"
    end
  end

  describe "ValidateSqlQueries.run_*_queries" do
    let(:rails_query) { "Appeal.count" }
    let(:sql_query) { "SELECT COUNT(*) FROM appeals" }
    let(:extracted_queries) do
      {
        rails_query: rails_query,
        sql_query: sql_query
      }
    end

    def run_queries(queries, &check_results)
      ValidateSqlQueries.run_rails_query(**queries, &check_results)
      ValidateSqlQueries.run_sql_query(**queries, &check_results)
    end

    context "valid queries" do
      it "executes queries without error" do
        aggregate_failures do
          run_queries(extracted_queries) do |result_key, result, error|
            expect(%w[rb sql].include?(result_key))
            expect(result.to_s).to eq "0"
            expect(error).to be_nil
          end
        end
      end
    end
    context "queries don't produce same result" do
      let(:sql_query) { "SELECT 123" }
      it "presents results that don't match" do
        results = []
        aggregate_failures do
          run_queries(extracted_queries) do |result_key, result, error|
            expect(%w[rb sql].include?(result_key))
            results << result.to_s
            expect(error).to be_nil
          end
        end
        expect(results.first).not_to eq results.second
      end
    end
    context "empty Rails query" do
      let(:rails_query) { "" }
      it "raises error" do
        expect { run_queries(extracted_queries) }.to raise_error(RuntimeError, /No Rails query found/)
      end
    end
    context "invalid Rails query" do
      let(:rails_query) { "Appeal.countZZ" }
      it "raises an error" do
        result_error = nil
        expect do
          run_queries(extracted_queries) { |_result_key, _result, error| result_error = error }
        end.to raise_error(NoMethodError)
        expect(result_error.class).to eq NoMethodError
      end
    end
    context "invalid SQL query" do
      let(:sql_query) { "ZZSELECT COUNT(*) FROM appeals" }
      it "raises StatementInvalid error" do
        results = {}
        expect do
          run_queries(extracted_queries) do |result_key, result, error|
            results[result_key] = { result: result, error: error }
          end
        end.to raise_error(ActiveRecord::StatementInvalid)

        # rails_query runs correctly
        expect(results["rb"][:result].to_s).to eq "0"
        expect(results["rb"][:error]).to be_nil

        # but sql_query fails
        expect(results["sql"][:result].to_s).to include "ERROR with query:"
        expect(results["sql"][:error].class).to eq ActiveRecord::StatementInvalid
      end
    end
    context "invalid rails_sql_postproc query" do
      before { extracted_queries[:rails_sql_postproc] = "each_row.mapZZ{|r| r.to_s}" }
      it "raises an error" do
        results = {}
        expect do
          run_queries(extracted_queries) do |result_key, result, error|
            results[result_key] = { result: result, error: error }
          end
        end.to raise_error(NoMethodError)

        # rails_query runs correctly
        expect(results["rb"][:result].to_s).to eq "0"
        expect(results["rb"][:error]).to be_nil

        # but rails_sql_postproc fails
        expect(results["sql"][:result].to_s).to include "ERROR with query:"
        expect(results["sql"][:error].class).to eq NoMethodError
      end
    end
  end
end
