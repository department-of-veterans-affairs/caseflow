# frozen_string_literal: true

class HearingSchedule::ValidateJudgeSpreadsheet
  SPREADSHEET_TITLE = "Judge Non-Availability Dates"
  SPREADSHEET_HEADERS = [nil, "Judge Name", "VLJ #", "Date"].freeze
  SPREADSHEET_EMPTY_COLUMN = [nil].freeze

  class JudgeDatesNotCorrectFormat < StandardError; end
  class JudgeTemplateNotFollowed < StandardError; end
  class JudgeDatesNotUnique < StandardError; end
  class JudgeDatesNotInRange < StandardError; end
  class JudgeNotInDatabase < StandardError; end

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
      @errors << JudgeTemplateNotFollowed
    end
  end

  # This method is only used in dev/demo mode to test the judge spreadsheet functionality
  # :nocov:
  def find_or_create_judges_in_vacols(vacols_judges, name, vlj_id)
    return unless Rails.env.development? || Rails.env.demo?

    if vacols_judges[vlj_id] &&
       vacols_judges[vlj_id][:first_name] == name.split(", ")[1].strip &&
       vacols_judges[vlj_id][:last_name] == name.split(", ")[0].strip
      true
    else
      User.create_judge_in_vacols(name.split(", ")[1].strip, name.split(", ")[0].strip, vlj_id)
    end
  end
  # :nocov:

  def judge_in_vacols?(vacols_judges, name, vlj_id)
    return find_or_create_judges_in_vacols(vacols_judges, name, vlj_id) if Rails.env.development? || Rails.env.demo?

    vacols_judges[vlj_id] &&
      vacols_judges[vlj_id][:first_name].casecmp(name.split(", ")[1].strip.downcase).zero? &&
      vacols_judges[vlj_id][:last_name].casecmp(name.split(", ")[0].strip.downcase).zero?
  end

  def check_range_of_dates(date)
    !date.instance_of?(Date) || (date >= @start_date && date <= @end_date)
  end

  def validate_judge_non_availability_dates
    vacols_judges = User.css_ids_by_vlj_ids(@spreadsheet_data.pluck("vlj_id").uniq)
    unless @spreadsheet_data.all? { |row| row["date"].instance_of?(Date) || row["date"] == "N/A" }
      @errors << JudgeDatesNotCorrectFormat
    end
    unless @spreadsheet_data.uniq == @spreadsheet_data
      @errors << JudgeDatesNotUnique
    end
    unless @spreadsheet_data.all? { |row| check_range_of_dates(row["date"]) }
      @errors << JudgeDatesNotInRange
    end
    unless @spreadsheet_data.all? { |row| judge_in_vacols?(vacols_judges, row["name"], row["vlj_id"]) }
      @errors << JudgeNotInDatabase
    end
  end

  def validate
    validate_judge_non_availability_template
    validate_judge_non_availability_dates
    @errors
  end
end
