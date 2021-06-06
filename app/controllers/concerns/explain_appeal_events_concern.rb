# frozen_string_literal: true

require "action_view"

##
# Used by ExplainController to build the data for presenting events based on
# exported data from SanitizedJsonExporter sje.

# :reek:FeatureEnvy
module ExplainAppealEventsConcern
  extend ActiveSupport::Concern

  def appeal_as_event_data(last_timestamp)
    all_events = sje.records_hash[Appeal.table_name].map do |appeal|
      mapper = Explain::AppealRecordEventMapper.new(appeal)
      mapper.events + mapper.timing_events(last_timestamp)
    end
    all_events += sje.records_hash[Intake.table_name].map do |intake|
      Explain::IntakeRecordEventMapper.new(intake, object_id_cache).events
    end
    all_events += sje.records_hash[DecisionDocument.table_name].map do |decis_doc|
      Explain::DecisionDocumentRecordEventMapper.new(decis_doc).events
    end
    # To-do: judge_case_reviews, attorney_case_reviews
    all_events.flatten.compact.sort
  end

  def tasks_as_event_data
    sje.records_hash[Task.table_name].map do |task|
      Explain::TaskRecordEventMapper.new(task, object_id_cache).events
    end.flatten.compact.sort
  end

  # rubocop:disable Metrics/AbcSize
  def request_issues_as_event_data
    req_issues = sje.records_hash[RequestIssue.table_name].index_by { |req| req["id"] }
    dec_issues = sje.records_hash[DecisionIssue.table_name].index_by { |dec| dec["id"] }

    events = []
    sje.records_hash[RequestDecisionIssue.table_name].each do |req_dec_issue|
      req_issue = req_issues[req_dec_issue["request_issue_id"]]
      dec_issue = dec_issues[req_dec_issue["decision_issue_id"]]
      events += Explain::RequestIssueRecordEventMapper.new(req_issue).events
      events += Explain::DecisionIssueRecordEventMapper.new(dec_issue, req_issue).events
    end

    # Remove records after processing them.
    # Don't remove them while processing because multiple request_issues can map to same decision_issue.
    sje.records_hash[RequestDecisionIssue.table_name].each do |req_dec_issue|
      req_issues.delete(req_dec_issue["request_issue_id"])
      dec_issues.delete(req_dec_issue["decision_issue_id"])
    end
    fail "Remaining DecisionIssue are not associated: #{dec_issues}" unless dec_issues.blank?

    # Process remaining req_issues
    req_issues.values.map do |req_issue|
      events += Explain::RequestIssueRecordEventMapper.new(req_issue).events
    end

    events.flatten.compact.sort
  end
  # rubocop:enable Metrics/AbcSize

  private

  # :reek:NestedIterators
  def records_hash_for(appeal)
    sje.records_hash.map do |table_name, records|
      next unless records.is_a?(Array)

      filtered_records = records.select do |record|
        record.find do |attrib_name, value|
          value == appeal["id"] && attrib_name.end_with?("id")
        end
      end
      [table_name, filtered_records]
    end.compact.to_h
  end

  def object_id_cache
    @object_id_cache ||= {
      # appeals: sje.records_hash[Appeal.table_name].map { |appeal| [appeal["id"], appeal["name"]] }.to_h,
      orgs: sje.records_hash[Organization.table_name].map { |org| [org["id"], org["name"]] }.to_h,
      users: sje.records_hash[User.table_name].map { |user| [user["id"], user["css_id"]] }.to_h,
      tasks: sje.records_hash[Task.table_name].map { |task| [task["id"], "#{task['type']}_#{task['id']}"] }.to_h
    }
  end
end
