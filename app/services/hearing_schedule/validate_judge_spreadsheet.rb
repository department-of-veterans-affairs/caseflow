# frozen_string_literal: true

class HearingSchedule::ValidateJudgeSpreadsheet
  SPREADSHEET_HEADERS = ["ID", "VLJ ID", "VLJ"].freeze

  TEMPLATE_ERROR = "The template was not followed. Please redownload the template and try again."
  WRONG_DATE_FORMAT_ERROR = "These dates are in the wrong format: "

  class JudgeTemplateNotFollowed < StandardError; end
  class JudgeDatesNotUnique < StandardError; end
  class JudgeNotInDatabase < StandardError; end
  class JudgeIdMismatchedName < StandardError; end

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

  def filter_nonunique_judges
    HearingSchedule::UniquenessValidators.new(@spreadsheet_data).duplicate_rows.pluck(:vlj_id).uniq
  end

  def filter_judges_not_in_db
    vacols_judges = User.css_ids_by_vlj_ids(@spreadsheet_data.pluck(:vlj_id).uniq)
    @spreadsheet_data.reject { |row| judge_in_vacols?(vacols_judges, row[:name], row[:vlj_id]) }.pluck(:vlj_id).compact
  end

  def filter_mismatched_judge_ids
    errors = []
    @spreadsheet_data.each do |data|
      judge = User.css_ids_by_vlj_ids(data[:vlj_id])
      first_name_match = judge[data[:vlj_id]][:first_name].casecmp(data[:name].split(", ")[1].strip.downcase).zero?
      last_name_match = judge[data[:vlj_id]][:last_name].casecmp(data[:name].split(", ")[0].strip.downcase).zero?
      next if first_name_match && last_name_match

      first_name = judge[data[:vlj_id]][:last_name]
      last_name = judge[data[:vlj_id]][:first_name]

      errors << "VLJ ID: #{data[:vlj_id]} expected name #{first_name}, #{last_name} but received name #{data[:name]}"
    end
    errors
  end

  def validate_judge_assignments
    nonunique_judges = filter_nonunique_judges
    if nonunique_judges.count > 0
      @errors << JudgeDatesNotUnique.new("These judges have duplicate dates: " + nonunique_judges.to_s)
    end

    judges_not_in_db = filter_judges_not_in_db
    if judges_not_in_db.count > 0
      @errors << JudgeNotInDatabase.new("These judges are not in the database: " + judges_not_in_db.to_s)
    end

    judge_names_not_matching_ids = filter_mismatched_judge_ids
    if judge_names_not_matching_ids.count > 0
      message = "These judge names do not match the IDs provided: " + judge_names_not_matching_ids.to_s
      @errors << JudgeIdMismatchedName.new(message)
    end
  end

  def validate
    validate_judge_assignment_template
    validate_judge_assignments
    @errors
  end
end
