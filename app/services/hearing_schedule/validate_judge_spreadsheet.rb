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
    # If no user is returned, the css_id is incorrect
    user = find_judge_by_css_id(css_id)
    return false if user.blank?

    # If the css_id matches, also check the name
    judge_name_matches?(user, name)
  end

  def judge_name_matches?(user, name)
    return if name.nil?

    # Name should be in "Last, First" format
    split_name = name.split(", ")
    full_name = "#{split_name.last} #{split_name.first}"

    user.full_name.casecmp?(full_name)
  end

  def find_judge_by_css_id(css_id)
    CachedUser.find_by(sdomainid: css_id)
  end

  def filter_judges_not_in_db
    not_in_db = @spreadsheet_data.reject do |row|
      judge_css_id_and_name_match_record?(row[:name], row[:judge_css_id])
    end

    # Do something here to add the reason and return it
    not_in_db.pluck(:judge_css_id, :name).compact
  end

  def validate_judge_assignments
    judges_not_in_db = filter_judges_not_in_db
    if judges_not_in_db.count > 0
      @errors << JudgeNotInDatabase.new("These judges are not in the database: " + judges_not_in_db.uniq.to_s)
    end
  end

  def validate
    validate_judge_assignment_template
    validate_judge_assignments
    @errors
  end
end
