# frozen_string_literal: true

# Data integrity checker for notifying when an appeal has multiple open HearingTask children
class AppealsWithMoreThanOneOpenHearingTaskChecker < DataIntegrityChecker
  #   AppealsWithMoreThanOneOpenHearingTaskChecker
  #   appeals_with_more_than_one_open_hearing_task_checker
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper

  def call
    build_report(appeals_with_more_than_one_open_hearing_task)
  end

  def slack_channel
    "#appeals-tango"
  end

  private

  HELP_DOCUMENT_LINK = "https://github.com/department-of-veterans-affairs/appeals-deployment/" \
    "wiki/Resolving-Hearing-Data-Issues#appeals-with-more-than-one-open-hearing-task"

  def appeals_with_more_than_one_open_hearing_task
    HearingTask
      .where("status IN (?)", Task.open_statuses)
      .group(:appeal_id, :appeal_type)
      .select("appeal_id, appeal_type, COUNT(*)")
      .having("COUNT(*) > 1")
      .map(&:appeal)
      .uniq
  end

  def build_report(appeals)
    return if appeals.empty?

    appeals_count = appeals.count

    add_to_report "Found #{appeals_count} #{'appeal'.pluralize(appeals_count)} with more than one open hearing task: "
    appeals.each do |appeal|
      add_to_report "`#{appeal.class.name}.find(#{appeal.id})` " \
        "(#{appeal.tasks.open.where(type: HearingTask.name).length} open HearingTasks)"
    end

    add_to_report "Follow the instructions in *<#{HELP_DOCUMENT_LINK}|this document>* to resolve."
  end
end
