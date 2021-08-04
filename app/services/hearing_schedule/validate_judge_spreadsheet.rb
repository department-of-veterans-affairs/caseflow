# frozen_string_literal: true

class HearingSchedule::ValidateJudgeSpreadsheet
  SPREADSHEET_HEADERS = ["ID", "VLJ ID", "VLJ"].freeze

  TEMPLATE_ERROR = "The template was not followed. Please redownload the template and try again."
  WRONG_DATE_FORMAT_ERROR = "These dates are in the wrong format: "

  class JudgeTemplateNotFollowed < StandardError; end
  class JudgeNotInDatabase < StandardError; end

  def initialize(spreadsheet)
    @errors = []
    @spreadsheet_template = spreadsheet.judge_assignment_template
    @spreadsheet_data = spreadsheet.judge_assignments
  end

  def validate_judge_assignment_template
    unless @spreadsheet_template.values == SPREADSHEET_HEADERS
      @errors << JudgeTemplateNotFollowed.new(TEMPLATE_ERROR)
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
    return if name.nil?

    return find_or_create_judges_in_vacols(vacols_judges, name, vlj_id) if Rails.env.development? || Rails.env.demo?

    vacols_judges[vlj_id] &&
      vacols_judges[vlj_id][:first_name].casecmp(name.split(", ")[1].strip.downcase).zero? &&
      vacols_judges[vlj_id][:last_name].casecmp(name.split(", ")[0].strip.downcase).zero?
  end

  def filter_judges_not_in_db
    vacols_judges = User.css_ids_by_vlj_ids(@spreadsheet_data.pluck(:vlj_id).uniq)
    @spreadsheet_data.reject { |row| judge_in_vacols?(vacols_judges, row[:name], row[:vlj_id]) }.pluck(:vlj_id).compact
  end

  def validate_judge_assignments
    judges_not_in_db = filter_judges_not_in_db
    if judges_not_in_db.count > 0
      @errors << JudgeNotInDatabase.new("These judges are not in the database: " + judges_not_in_db.to_s)
    end
  end

  def validate
    validate_judge_assignment_template
    validate_judge_assignments
    @errors
  end
end
