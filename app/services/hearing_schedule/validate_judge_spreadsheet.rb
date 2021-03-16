# frozen_string_literal: true

class HearingSchedule::ValidateJudgeSpreadsheet
  SPREADSHEET_TITLE = "Judge Non-Availability Dates"
  SPREADSHEET_HEADERS = [nil, "Judge Name", "VLJ #", "Date"].freeze
  SPREADSHEET_EMPTY_COLUMN = [nil].freeze

  TEMPLATE_ERROR = "The template was not followed. Please redownload the template and try again."
  WRONG_DATE_FORMAT_ERROR = "These dates are in the wrong format: "

  class JudgeDatesNotCorrectFormat < StandardError; end
  class JudgeTemplateNotFollowed < StandardError; end
  class JudgeDatesNotUnique < StandardError; end
  class JudgeDatesNotInRange < StandardError; end
  class JudgeIdNotInDatabase < StandardError; end
  class JudgeNameDoesNotMatchIdInDatabase < StandardError; end

  def initialize(spreadsheet, start_date, end_date)
    get_spreadsheet_data = HearingSchedule::GetSpreadsheetData.new(spreadsheet)
    @errors = []
    @spreadsheet_template = get_spreadsheet_data.judge_non_availability_template
    @spreadsheet_data = get_spreadsheet_data.judge_non_availability_data
    @start_date = start_date
    @end_date = end_date
  end

  def validate_judge_non_availability_template
    unless @spreadsheet_template[:title] == SPREADSHEET_TITLE &&
           @spreadsheet_template[:headers] == SPREADSHEET_HEADERS &&
           @spreadsheet_template[:empty_column] == SPREADSHEET_EMPTY_COLUMN
      @errors << JudgeTemplateNotFollowed.new(TEMPLATE_ERROR)
    end
  end

  def filter_incorrectly_formatted_dates
    @spreadsheet_data.reject do |row|
      HearingSchedule::DateValidators.new(row[:date]).date_correctly_formatted?
    end.pluck(:date)
  end

  def filter_nonunique_judges
    HearingSchedule::UniquenessValidators.new(@spreadsheet_data).duplicate_rows.pluck(:vlj_id).uniq
  end

  def filter_out_of_range_dates
    out_of_range_dates = @spreadsheet_data.reject do |row|
      HearingSchedule::DateValidators.new(row[:date], @start_date, @end_date).date_in_range?
    end.pluck(:date)

    out_of_range_dates.map { |date| date.strftime("%m/%d/%Y") }
  end

  # This method smells of :reek:UtilityFunction
  def judge_name_matches(row, vacols_judges)
    last_name, first_name = row[:name].split(", ").map(&:strip)

    vacols_judges[row[:vlj_id]][:first_name].casecmp(first_name).zero? &&
      vacols_judges[row[:vlj_id]][:last_name].casecmp(last_name).zero?
  end

  def filter_rows_by_error
    vacols_judges = User.css_ids_by_vlj_ids(@spreadsheet_data.pluck(:vlj_id).uniq)

    # get rows with and without matching ids
    rows_with_judge_id_match, rows_without_judge_id_match = @spreadsheet_data.partition do |row|
      vacols_judges[row[:vlj_id]].present?
    end

    # check rows with matching ids for wrong names
    rows_without_judge_name_match = rows_with_judge_id_match.reject do |row|
      judge_name_matches(row, vacols_judges)
    end

    [rows_without_judge_id_match, rows_without_judge_name_match]
  end

  def validate_judge_non_availability_dates
    incorrectly_formatted_dates = filter_incorrectly_formatted_dates
    if incorrectly_formatted_dates.count > 0
      @errors << JudgeDatesNotCorrectFormat.new(WRONG_DATE_FORMAT_ERROR + incorrectly_formatted_dates.to_s)
    end
    nonunique_judges = filter_nonunique_judges
    if nonunique_judges.count > 0
      @errors << JudgeDatesNotUnique.new("These judges have duplicate dates: " + nonunique_judges.to_s)
    end
    out_of_range_dates = filter_out_of_range_dates
    if out_of_range_dates.count > 0
      @errors << JudgeDatesNotInRange.new("These dates are out of the selected range: " + out_of_range_dates.to_s)
    end
  end

  def validate_judge_ids_and_names
    rows_without_judge_id_match, rows_without_judge_name_match = filter_rows_by_error
    if rows_without_judge_id_match.count > 0
      @errors << JudgeIdNotInDatabase.new(
        "These judges ids are not in the database: " + rows_without_judge_id_match.pluck(:vlj_id).join(", ")
      )
    end
    if rows_without_judge_name_match.count > 0
      @errors << JudgeNameDoesNotMatchIdInDatabase.new(
        "These judges names do not match the database: " +
          rows_without_judge_name_match.map { |row| "\"#{row[:name]}\" (id: #{row[:vlj_id]})" }.join("; ")
      )
    end
  end

  def validate
    validate_judge_non_availability_template
    validate_judge_non_availability_dates
    validate_judge_ids_and_names
    @errors
  end
end
