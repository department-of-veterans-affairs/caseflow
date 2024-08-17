# frozen_string_literal: true

class RequestIssueUpdateEvent < RequestIssuesUpdate
  # That how it works with RequestIssuesUpdate:
  # on first step instance of RequestIssuesUpdate creating, after it .perform! method calling
  # RequestIssuesUpdate.new(
  #   user: user,
  #   review: review,
  #   parser: parser
  # )
  def perform!
    return false unless validate_before_perform
    return false if processed?

    transaction do
      process_issues!
      review.mark_rating_request_issues_to_reassociate! # ???
      update!(
        before_request_issue_ids: before_issues.map(&:id), # ???
        after_request_issue_ids: after_issues.map(&:id), # ???
        withdrawn_request_issue_ids: withdrawn_issues.map(&:id), # ???
        edited_request_issue_ids: edited_issues.map(&:id) # ???
      )
      cancel_active_tasks
      submit_for_processing!
    end

    process_job

    true
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def process_job
    if run_async?
      DecisionReviewProcessJob.perform_later(self)
    else
      DecisionReviewProcessJob.perform_now(self)
    end
  end

  # establish! is called async via DecisionReviewProcessJob.
  # it is queued via submit_for_processing! in the perform! method above.
  def establish!
    attempted!

    review.establish!
    edited_issues.each { |issue| RequestIssueContention.new(issue).update_text! }
    potential_end_products_to_remove = []
    removed_or_withdrawn_issues.select(&:end_product_establishment).each do |request_issue|
      RequestIssueContention.new(request_issue).remove!
      potential_end_products_to_remove << request_issue.end_product_establishment
    end

    potential_end_products_to_remove.uniq.each(&:cancel_unused_end_product!)
    clear_error!
    processed!
  end

  def added_issues
    # after_issues - before_issues
    calculate_added_issues
  end

  def removed_issues
    # before_issues - after_issues
    calculate_removed_issues
  end

  def withdrawn_issues
    @withdrawn_issues ||= withdrawn_request_issue_ids ? fetch_withdrawn_issues : calculate_withdrawn_issues
  end

  def removed_or_withdrawn_issues
    removed_issues + withdrawn_issues
  end

  def before_issues
    @before_issues ||= before_request_issue_ids ? fetch_before_issues : calculate_before_issues
  end

  def after_issues
    @after_issues ||= after_request_issue_ids ? fetch_after_issues : calculate_after_issues
  end

  def edited_issues
    @edited_issues ||= edited_request_issue_ids ? fetch_edited_issues : calculate_edited_issues
  end

  def all_updated_issues
    added_issues + removed_issues + withdrawn_issues + edited_issues
  end

  def can_be_performed?
    validate_before_perform
  end

  private

  def changes?
    all_updated_issues.any?
  end

  def calculate_after_issues
    # # need to calculate and store before issues before we add new request issues
    # before_issues

    # @request_issues_data.map do |issue_data|
    #   request_issue = review.find_or_build_request_issue_from_intake_data(issue_data)

    #   # If the data has a issue modification request id here, then add it in as an association
    #   issue_modification_request_id = issue_data[:issue_modification_request_id]
    #   if issue_modification_request_id && request_issue
    #     issue_modification_request = IssueModificationRequest.find(issue_modification_request_id)
    #     request_issue.issue_modification_requests << issue_modification_request
    #   end

    #   request_issue
    # end
    before_issues + added_issues - removed_issues
  end

  def calculate_edited_issues
    edited_issue_data.map do |issue_data|
      review.find_or_build_request_issue_from_intake_data(issue_data)
    end
  end

  def calculate_added_issues
    parser.added_issues.map do |issue_data|
      review.find_or_build_request_issue_from_intake_data(issue_data)
    end
  end

  def calculate_withdrawn_issues
    parser.withdrawn_issues.map do |issue_data|
      review.find_or_build_request_issue_from_intake_data(issue_data)
    end
  end

  def calculate_removed_issues
    parser.removed_issues.map do |issue_data|
      review.request_issues.find(issue_data[:id])
    end
  end

  def edited_issue_data
    return [] unless @request_issues_data

    @request_issues_data.select do |ri|
      edited_issue?(ri)
    end
  end

  def edited_issue?(request_issue)
    (request_issue[:edited_description].present? || request_issue[:edited_decision_date].present?) &&
      request_issue[:request_issue_id]
  end

  # currently existing request issues of that review
  def calculate_before_issues
    review.request_issues.active_or_ineligible.select(&:persisted?)
  end

  def validate_before_perform
    if !changes?
      @error_code = :no_changes
    elsif RequestIssuesUpdate.where(review: review).where.not(id: id).processable.exists?
      @error_code = :previous_update_not_done_processing
    end

    !@error_code
  end

  def fetch_before_issues
    RequestIssue.where(id: before_request_issue_ids)
  end

  def fetch_after_issues
    RequestIssue.where(id: after_request_issue_ids)
  end

  def fetch_edited_issues
    RequestIssue.where(id: edited_request_issue_ids)
  end

  def fetch_withdrawn_issues
    RequestIssue.where(id: withdrawn_request_issue_ids)
  end

  def process_issues!
    # create_issues! create that end product establishment if it doesn't exist (claim_review model). ?Probably not necessary?.
    review.create_issues!(added_issues, self)
    process_removed_issues!
    process_legacy_issues!
    process_withdrawn_issues!
    process_edited_issues!
  end

  def process_legacy_issues!
    LegacyOptinManager.new(decision_review: review).process!
  end

  def process_withdrawn_issues!
    # withdrawal.call

    return if withdrawn_issues.empty?

    withdrawal_date = withdrawn_issue_data.first[:withdrawal_date]
    withdrawn_issues.each { |ri| ri.withdraw!(withdrawal_date) }
  end

  def process_edited_issues!
    return if edited_issues.empty?

    edited_issue_data.each do |edited_issue|
      request_issue = RequestIssue.find(edited_issue[:request_issue_id].to_s)
      edit_contention_text(edited_issue, request_issue)
      edit_decision_date(edited_issue, request_issue)
    end
  end

  def edit_contention_text(edited_issue_params, request_issue)
    if edited_issue_params[:edited_description]
      request_issue.save_edited_contention_text!(edited_issue_params[:edited_description])
    end
  end

  def edit_decision_date(edited_issue_params, request_issue)
    if edited_issue_params[:edited_decision_date]
      request_issue.save_decision_date!(edited_issue_params[:edited_decision_date])
    end
  end

  def process_removed_issues!
    removed_issues.each(&:remove!)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # :reek:FeatureEnvy
  def create_issue_update_task(change_type, before_issue)
    transaction do
      # close out any tasks that might be open
      open_issue_task = Task.where(
        assigned_to: SpecialIssueEditTeam.singleton
      ).where(status: "assigned").where(appeal: before_issue.decision_review)
      open_issue_task[0].delete unless open_issue_task.empty?

      task = IssuesUpdateTask.create!(
        appeal: before_issue.decision_review,
        parent: RootTask.find_by(appeal: before_issue.decision_review),
        assigned_to: SpecialIssueEditTeam.singleton,
        assigned_by: RequestStore[:current_user],
        completed_by: RequestStore[:current_user]
      )

      # if a new issue is added and VBMS was edited, reference the original status
      if change_type == "Added Issue"
        set = CaseTimelineInstructionSet.new(
          change_type: change_type,
          issue_category: before_issue.contested_issue_description,
          benefit_type: before_issue.benefit_type&.capitalize
        )
      else
        # format the task instructions and close out
        # use contested issue description if nonrating issue category is nil

        issue_description = "#{before_issue.nonrating_issue_category} - #{before_issue.nonrating_issue_description}" unless before_issue.nonrating_issue_category.nil?
        issue_description = before_issue.contested_issue_description if issue_description.nil?
        set = CaseTimelineInstructionSet.new(
          change_type: change_type,
          issue_category: issue_description,
          benefit_type: before_issue.benefit_type&.capitalize
        )
      end
      task.format_instructions(set)
      task.completed!

      # create SpecialIssueChange record to log the changes
      SpecialIssueChange.create!(
        issue_id: before_issue.id,
        appeal_id: before_issue.decision_review.id,
        appeal_type: "Appeal",
        task_id: task.id,
        created_at: Time.zone.now.utc,
        created_by_id: RequestStore[:current_user].id,
        created_by_css_id: RequestStore[:current_user].css_id,
        change_category: change_type
      )
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
