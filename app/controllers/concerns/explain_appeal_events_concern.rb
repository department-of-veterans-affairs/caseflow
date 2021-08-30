# frozen_string_literal: true

require "action_view"

##
# Used by ExplainController to build the data for presenting events based on
# exported data from SanitizedJsonExporter sje.
# Specifically, this data is used to build the Appeal Narrative.

# :reek:FeatureEnvy
module ExplainAppealEventsConcern
  extend ActiveSupport::Concern

  def appeal_object_id
    @appeal_object_id ||= "#{appeal.class.name}_#{appeal.id}"
  end

  # :reek:FeatureEnvy
  def event_table_data
    task_events = tasks_as_event_data
    events = appeal_as_event_data(task_events.last&.timestamp) +
             task_events +
             request_issues_as_event_data +
             hearings_as_event_data
    events.sort.map(&:as_json)
  end

  def appeal_as_event_data(last_timestamp)
    all_events = exported_records(Appeal).map do |appeal|
      mapper = Explain::AppealRecordEventMapper.new(appeal)
      mapper.events + mapper.timing_events(last_timestamp)
    end
    all_events += exported_records(Intake).map do |intake|
      Explain::IntakeRecordEventMapper.new(intake, object_id_cache).events
    end
    all_events += exported_records(DecisionDocument).map do |decis_doc|
      Explain::DecisionDocumentRecordEventMapper.new(decis_doc).events
    end
    # To-do: judge_case_reviews, attorney_case_reviews
    all_events.flatten.compact.sort
  end

  def tasks_as_event_data
    exported_records(Task).map do |task|
      Explain::TaskRecordEventMapper.new(task, object_id_cache).events
    end.flatten.compact.sort
  end

  # rubocop:disable Metrics/AbcSize
  def request_issues_as_event_data
    req_issues = exported_records(RequestIssue).index_by { |req| req["id"] }
    dec_issues = exported_records(DecisionIssue).index_by { |dec| dec["id"] }

    events = []
    exported_records(RequestDecisionIssue).each do |req_dec_issue|
      req_issue = req_issues[req_dec_issue["request_issue_id"]]
      dec_issue = dec_issues[req_dec_issue["decision_issue_id"]]
      events += Explain::RequestIssueRecordEventMapper.new(req_issue).events
      events += Explain::DecisionIssueRecordEventMapper.new(dec_issue, req_issue).events
    end

    # Remove records after processing them.
    # Don't remove them while processing because multiple request_issues can map to the same decision_issue.
    exported_records(RequestDecisionIssue).each do |req_dec_issue|
      req_issues.delete(req_dec_issue["request_issue_id"])
      dec_issues.delete(req_dec_issue["decision_issue_id"])
    end

    # Process remaining req_issues
    req_issues.values.map do |req_issue|
      events += Explain::RequestIssueRecordEventMapper.new(req_issue).events
    end

    # Remaining DecisionIssue are likely req_issues.contested_decision_issues,
    # which are associated with another decision review, e.g., Appeal, HLR, or SC.
    # These will be presented in other visualizations.
    exported_records(RequestIssue).each { |req_issue| dec_issues.delete(req_issue["contested_decision_issue_id"]) }

    # Warn in case we missed processing some
    Rails.logger.warn("Remaining unaccounted DecisionIssues: #{dec_issues}") unless dec_issues.blank?

    events.flatten.compact.sort
  end
  # rubocop:enable Metrics/AbcSize

  def hearings_as_event_data
    hearing_days = exported_records(HearingDay).index_by { |rec| rec["id"] }
    virtual_hearings = exported_records(VirtualHearing).index_by { |rec| rec["hearing_id"] }
    exported_records(Hearing).map do |hearing|
      hearing_day = hearing_days[hearing["hearing_day_id"]]
      virtual_hearing = virtual_hearings[hearing["id"]]
      Explain::HearingRecordEventMapper.new(hearing, hearing_day, virtual_hearing, object_id_cache).events
    end.flatten.compact.sort
  end

  private

  # # :reek:NestedIterators
  # def records_hash_for(appeal)
  #   exported_records(map)|table_name, records|
  #     next unless records.is_a?(Array)

  #     filtered_records = records.select do |record|
  #       record.find do |attrib_name, value|
  #         value == appeal["id"] && attrib_name.end_with?("_id")
  #       end
  #     end
  #     [table_name, filtered_records]
  #   end.compact.to_h
  # end

  def object_id_cache
    @object_id_cache ||= {
      # appeals: exported_records(Appeal).map { |appeal| [appeal["id"], appeal["name"]] }.to_h,
      orgs: exported_records(Organization).map { |org| [org["id"], org["name"]] }.to_h,
      users: exported_records(User).map { |user| [user["id"], user["css_id"]] }.to_h,
      tasks: exported_records(Task).map { |task| [task["id"], "#{task['type']}_#{task['id']}"] }.to_h
    }
  end
end
