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

  def judge_css_id_and_name_match_record?(name, css_id)
    return if name.nil?

    user = CachedUser.find_by(sdomainid: css_id)
    return if user.nil?

    # we get the name in the format "Last, First"
    split_name = name.split(", ")
    full_name = "#{split_name.last} #{split_name.first}"

    user.full_name.casecmp?(full_name)
  end

  def filter_judges_not_in_db
    @spreadsheet_data.reject do |row|
      judge_css_id_and_name_match_record?(row[:name], row[:judge_css_id])
    end.pluck(:judge_css_id, :name).compact
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
