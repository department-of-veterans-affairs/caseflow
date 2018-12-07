module CaseReviewConcern
  extend ActiveSupport::Concern

  attr_accessor :issues

  included do
    validates :task, presence: true, unless: :legacy?
  end

  def appeal
    @appeal ||= if legacy?
                  LegacyAppeal.find_or_create_by(vacols_id: vacols_id)
                else
                  Task.find(task_id).appeal
                end
  end

  def update_task_and_issue_dispositions
    task.mark_as_complete!

    if task.type == "AttorneyTask" && task.assigned_by_id != reviewing_judge_id
      task.parent.update(assigned_to_id: reviewing_judge_id)
    end

    # Remove this check when feature flag 'ama_decision_issues' is enabled for all
    if FeatureToggle.enabled?(:ama_decision_issues, user: RequestStore.store[:current_user])
      delete_and_create_decision_issues
    else
      update_issue_dispositions
    end
  end

  def delete_and_create_decision_issues
    return unless appeal
    # We will always delete and re-create decision issues on attorney/judge checkout
    decision_issue_ids_to_delete = appeal.decision_issues.map(&:id)
    DecisionIssue.where(id: decision_issue_ids_to_delete).destroy_all

    issues.each do |issue_attrs|
      request_issues = appeal.request_issues.where(id: issue_attrs[:request_issue_ids])
      next if request_issues.empty?
      decision_issue = DecisionIssue.create!(
        disposition: issue_attrs[:disposition],
        description: issue_attrs[:description],
        participant_id: appeal.veteran.participant_id
      )
      request_issues.each do |request_issue|
        RequestDecisionIssue.create!(decision_issue: decision_issue, request_issue: request_issue)
      end
      create_remand_reasons(decision_issue, issue_attrs[:remand_reasons] || [])
    end
  end

  def create_remand_reasons(decision_issue, remand_reasons_attrs)
    remand_reasons_attrs.each do |attrs|
      decision_issue.remand_reasons.find_or_initialize_by(code: attrs[:code]).tap do |record|
        record.post_aoj = attrs[:post_aoj]
        record.save!
      end
    end
  end

  # Delete this method when feature flag 'ama_decision_issues' is enabled for all
  def update_issue_dispositions
    (issues || []).each do |issue_attrs|
      request_issue = appeal.request_issues.find_by(id: issue_attrs["id"]) if appeal
      next unless request_issue

      request_issue.update(disposition: issue_attrs["disposition"])
      # If disposition was remanded and now is changed to another dispostion,
      # delete all remand reasons associated with the request issue
      update_remand_reasons(request_issue, issue_attrs["remand_reasons"] || [])
    end
  end

  # Delete this method when feature flag 'ama_decision_issues' is enabled for all
  def update_remand_reasons(request_issue, remand_reasons_attrs)
    remand_reasons_attrs.each do |remand_reason_attrs|
      request_issue.remand_reasons.find_or_initialize_by(code: remand_reason_attrs["code"]).tap do |record|
        record.post_aoj = remand_reason_attrs["post_aoj"]
        record.save!
      end
    end
    # Delete remand reasons that are not part of the request
    existing_codes = request_issue.reload.remand_reasons.pluck(:code)
    codes_to_delete = existing_codes - remand_reasons_attrs.pluck("code")
    request_issue.remand_reasons.where(code: codes_to_delete).delete_all
  end

  def update_issue_dispositions_in_vacols!
    (issues || []).each do |issue_attrs|
      Issue.update_in_vacols!(
        vacols_id: vacols_id,
        vacols_sequence_id: issue_attrs[:id],
        issue_attrs: {
          vacols_user_id: modifying_user,
          disposition: issue_attrs[:disposition],
          disposition_date: VacolsHelper.local_date_with_utc_timezone,
          readjudication: issue_attrs[:readjudication],
          remand_reasons: issue_attrs[:remand_reasons]
        }
      )
    end
  end

  def legacy?
    (task_id =~ LegacyTask::TASK_ID_REGEX) ? true : false
  end

  def vacols_id
    task_id&.split("-", 2)&.first
  end

  def created_in_vacols_date
    task_id&.split("-", 2)&.second&.to_date
  end
end
