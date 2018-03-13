class QueueRepository
  class QueueError < StandardError; end
  # :nocov:
  def self.tasks_for_user(css_id)
    MetricsService.record("VACOLS: fetch user tasks",
                          service: :vacols,
                          name: "tasks_for_user") do
      tasks_query(css_id)
    end
  end

  def self.appeals_from_tasks(tasks)
    vacols_ids = tasks.map(&:vacols_id)

    appeals = MetricsService.record("VACOLS: fetch appeals and associated info for tasks",
                                    service: :vacols,
                                    name: "appeals_from_tasks") do
      case_records = QueueRepository.appeal_info_query(vacols_ids)
      aod_by_appeal = aod_query(vacols_ids)
      hearings_by_appeal = Hearing.repository.hearings_for_appeals(vacols_ids)
      issues_by_appeal = VACOLS::CaseIssue.descriptions(vacols_ids)

      case_records.map do |case_record|
        appeal = AppealRepository.build_appeal(case_record)

        appeal.aod = aod_by_appeal[appeal.vacols_id]
        appeal.issues = (issues_by_appeal[appeal.vacols_id] || []).map { |issue| Issue.load_from_vacols(issue) }
        appeal.hearings = hearings_by_appeal[appeal.vacols_id] || []

        appeal
      end
    end

    appeals.map(&:save)
    appeals
  end

  def self.reassign_case_to_judge(attorney_css_id:, judge_css_id:, decass_attrs:, issues:)
    binding.pry
    decass_record = find_decass_record(decass_attrs[:task_id])

    # update DECASS table
    update_decass_record(decass_record,
                         decass_attrs.merge(reassigned_at: VacolsHelper.local_date_with_utc_timezone))

    # update location with the judge's slogid
    update_location(case_record: decass_record.case, css_id: judge_css_id)

    # update dispositions on the issues
    update_issue_dispositions(css_id: attorney_css_id,
                              vacols_id: decass_record.defolder,
                              issues: issues) if issues
    true
  end

  def self.update_issue_dispositions(css_id:, vacols_id:, issues:)
    issues.each do |issue|
      IssueRepository.update_vacols_issue!(
        css_id: css_id,
        vacols_id: vacols_id,
        vacols_sequence_id: issue["vacols_sequence_id"],
        issue_attrs: { disposition: issue["disposition"], disposition_date: VacolsHelper.local_date_with_utc_timezone }
      )
    end
  rescue IssueRepository::IssueError => e
    fail QueueError, e
  end

  def self.decass_by_vacols_id_and_date_assigned(vacols_id, date_assigned)
    VACOLS::Decass.find_by(defolder: vacols_id, deassign: date_assigned)
  end

  def self.update_location(case_record:, css_id:)
    staff = VACOLS::Staff.find_by(sdomainid: css_id)
    fail QueueError, "Cannot find user with #{css_id} in VACOLS" unless staff
    case_record.update_vacols_location!(staff.slogid)
  end

  def self.update_decass_record(decass_record, decass_attrs)
    info = QueueMapper.rename_and_convert_decass_attrs(decass_attrs)
    decass_record.update_decass_record!(info)
  end

  def self.tasks_query(css_id)
    records = VACOLS::CaseAssignment.tasks_for_user(css_id)
    filter_duplicate_tasks(records)
  end

  def self.appeal_info_query(vacols_ids)
    VACOLS::Case.includes(:folder, :correspondent, :representative)
      .find(vacols_ids)
  end

  def self.aod_query(vacols_ids)
    VACOLS::Case.aod(vacols_ids)
  end
  # :nocov:

  def self.find_decass_record(task_id)
    # Task ID is a concatantion of the vacols ID and the date assigned
    result = task_id.split("-", 2)
    fail QueueError, "Task ID is invalid format: #{task_id}" if result.size != 2
    record = decass_by_vacols_id_and_date_assigned(result.first, result.second.to_date)
    # TODO: check permission that the user can update the record
    unless record
      fail QueueError,
           "Decass record does not exist for vacols_id: #{result.first} and date assigned: #{result.second}"
    end
    record
  end

  def self.filter_duplicate_tasks(records)
    # Keep the latest assignment if there are duplicate records
    records.group_by(&:vacols_id).each_with_object([]) { |(_k, v), result| result << v.sort_by(&:date_assigned).last }
  end
end
