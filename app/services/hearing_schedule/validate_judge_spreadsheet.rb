# frozen_string_literal: true

class HearingSchedule::ValidateJudgeSpreadsheet
  SPREADSHEET_HEADERS = ["ID", "CSS ID", "VLJ"].freeze

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

  def judge_css_id_matches_name?(name, css_id)
    return if name.nil?

    user = User.find_by_css_id(css_id)

    split_name = name.split(", ")
    full_name = "#{split_name[1]} #{split_name[0]}"

    # Last Name, First Name
    user.present? && user.full_name.casecmp?(full_name)
  end

  def filter_judges_not_in_db
    @spreadsheet_data.reject { |row| judge_css_id_matches_name?(row[:name], row[:css_id]) }.pluck(:css_id).compact
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
