# frozen_string_literal: true

class SearchQueryService
  def initialize(file_number: nil, docket_number: nil, veteran_ids: nil)
    @docket_number = docket_number
    @file_number = file_number
    @veteran_ids = veteran_ids
    @queries = SearchQueryService::Query.new
  end

  def search_by_veteran_file_number
    combined_results
  end

  def search_by_docket_number
    results = ActiveRecord::Base.connection.exec_query(
      sanitize(
        queries.docket_number_query(docket_number)
      )
    )

    results.map do |row|
      AppealRow.new(row).search_response
    end
  end

  def search_by_veteran_ids
    combined_results
  end

  private

  attr_reader :docket_number, :file_number, :queries, :veteran_ids

  def combined_results
    search_results.map do |row|
      if row["type"] != "legacy_appeal"
        AppealRow.new(row).search_response
      else
        vacols_row = vacols_results.find { |result| result["vacols_id"] == row["external_id"] }

        Rails.logger.warn(no_vacols_record_warning(result)) if vacols_row.blank?
        LegacyAppealRow.new(row, vacols_row || null_vacols_row).search_response
      end
    end
  end

  def null_vacols_row
    {}
  end

  def no_vacols_record_warning(result)
    <<-WARN
      No corresponding VACOLS record found for appeal with:
        id: #{result['id']}
        vacols_id: #{result['vacols_id']}
      searching with:
        #{file_number.present? "file_number #{file_number}"} \
        #{veteran_ids.present? "veteran_ids #{veteran_ids.join(',')}"} \
        #{file_number.present? "docket_number #{docket_number}"}
    WARN
  end

  def vacols_ids
    legacy_results.map { |result| result["external_id"] }
  end

  def legacy_results
    search_results.select { |result| result["type"] == "legacy_appeal" }
  end

  def search_results
    @search_results ||=
      if file_number.present?
        file_number_search_results
      else
        veteran_ids_search_results
      end
  end

  def veteran_ids_search_results
    ActiveRecord::Base
      .connection
      .exec_query(
        sanitize(queries.veteran_ids_query(veteran_ids))
      )
      .uniq { |result| result["external_id"] }
  end

  def file_number_search_results
    ActiveRecord::Base
      .connection
      .exec_query(file_number_or_ssn_query)
      .uniq { |result| result["external_id"] }
  end

  def file_number_or_ssn_query
    sanitize(
      queries.veteran_file_number_query(file_number)
    )
  end

  def vacols_results
    @vacols_results ||= begin
      vacols_query = VACOLS::Record.sanitize_sql_array(queries.vacols_query(vacols_ids))
      VACOLS::Record.connection.exec_query(vacols_query)
    end
  end

  def sanitize(values)
    ActiveRecord::Base.sanitize_sql_array(values)
  end
end
