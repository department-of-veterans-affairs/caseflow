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
    task.update(status: :completed)
    (issues || []).each do |issue|
      decision_issue = appeal.decision_issues.find_by(id: issue["id"]) if appeal
      decision_issue.update(disposition: issue["disposition"]) if decision_issue
    end
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
    (task_id =~ /\A[0-9A-Z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i) ? true : false
  end

  def vacols_id
    task_id.split("-", 2).first if task_id
  end

  def created_in_vacols_date
    task_id.split("-", 2).second.to_date if task_id
  end
end
