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
      @errors << JudgeTemplateNotFollowed.new("The template was not followed. Please redownload the template and try again.")
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

  def get_incorrectly_formatted_dates
    @spreadsheet_data.reject { |row| row["date"].instance_of?(Date) || row["date"] == "N/A" }.pluck("date")
  end

  def get_nonunique_judges
    @spreadsheet_data.select { |row| @spreadsheet_data.count(row) > 1 }.pluck("vlj_id").uniq
  end

  def get_out_of_range_dates
    @spreadsheet_data.reject do |row|
      !row["date"].instance_of?(Date) || (row["date"] >= @start_date && row["date"] <= @end_date)
    end.pluck("date").map { |date| date.strftime("%m/%d/%Y") }
  end

  def get_judges_not_in_db
    vacols_judges = User.css_ids_by_vlj_ids(@spreadsheet_data.pluck("vlj_id").uniq)
    @spreadsheet_data.select { |row| !judge_in_vacols?(vacols_judges, row["name"], row["vlj_id"]) }.pluck("vlj_id")
  end

  def validate_judge_non_availability_dates
    incorrectly_formatted_dates = get_incorrectly_formatted_dates
    if incorrectly_formatted_dates.count > 0
      @errors << JudgeDatesNotCorrectFormat.new("These dates are in the wrong format: " + incorrectly_formatted_dates.to_s)
    end
    nonunique_judges = get_nonunique_judges
    if nonunique_judges.count > 0
      @errors << JudgeDatesNotUnique.new("These judges have duplicate dates: " + nonunique_judges.to_s)
    end
    out_of_range_dates = get_out_of_range_dates
    if out_of_range_dates.count > 0
      @errors << JudgeDatesNotInRange.new("These dates are out of the selected range: " + out_of_range_dates.to_s)
    end
    judges_not_in_db = get_judges_not_in_db
    if judges_not_in_db.count > 0
      @errors << JudgeNotInDatabase.new("These judges are not in the database: " + judges_not_in_db.to_s)
    end
  end

  def validate
    validate_judge_non_availability_template
    validate_judge_non_availability_dates
    @errors
  end
end
