# frozen_string_literal: true

class SearchQueryService
  def initialize(file_number: nil, docket_number: nil)
    @docket_number = docket_number
    @file_number = file_number
    @queries = SearchQueryService::Query.new
  end

  def search_by_veteran_file_number
    search_results.map do |row|
      if row["type"] != "legacy_appeal"
        AppealRow.new(row).search_response
      else
        vacols_row = vacols_results.find { |result| result["vacols_id"] == row["external_id"] }
        LegacyAppealRow.new(row, vacols_row).search_response
      end
    end
  end

  def search_by_docket_number
    results = ActiveRecord::Base.connection.exec_query(
      sanitize([queries.docket_number_query, docket_number])
    )

    results.map do |row|
      AppealRow.new(row).search_response
    end
  end

  private

  attr_reader :docket_number, :file_number, :queries

  def vacols_ids
    legacy_results.map { |result| result["external_id"] }
  end

  def legacy_results
    search_results.select { |result| result["type"] == "legacy_appeal" }
  end

  def search_results
    @search_results = ActiveRecord::Base
      .connection
      .exec_query(file_number_or_ssn_query)
      .uniq { |result| result["external_id"] }
  end

  def file_number_or_ssn_query
    sanitize(
      [
        queries.veteran_file_number_query,
        *[file_number].cycle(queries.veteran_file_number_num_params).to_a
      ]
    )
  end

  def vacols_results
    @vacols_results ||= begin
      vacols_query = VACOLS::Record.sanitize_sql_array([queries.vacols_query, vacols_ids])
      VACOLS::Record.connection.exec_query(vacols_query)
    end
  end

  def sanitize(values)
    ActiveRecord::Base.sanitize_sql_array(values)
  end
end
