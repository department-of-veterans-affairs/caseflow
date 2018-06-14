module LegacyTaskConcern
  extend ActiveSupport::Concern

  included do
    # task ID is vacols_id concatenated with the date assigned
    validates :vacols_id, format: { with: /\A[0-9A-Z]+\Z/i }
    validates :created_in_vacols_date, format: { with: /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i }, allow_blank: true
  end

  attr_accessor :issues, :vacols_id, :created_in_vacols_date

  def appeal
    @appeal ||= LegacyAppeal.find_or_create_by(vacols_id: vacols_id)
  end

  def update_issue_dispositions!
    (issues || []).each do |issue_attrs|
      Issue.update_in_vacols!(
        vacols_id: vacols_id,
        vacols_sequence_id: issue_attrs[:vacols_sequence_id],
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

  def task_id
    "#{vacols_id}-#{created_in_vacols_date}"
  end

  def task_id=(value)
    vacols_id, created_in_vacols_date = task_id.split("-", 2)
  end
end
