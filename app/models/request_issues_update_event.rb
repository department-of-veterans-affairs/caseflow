# frozen_string_literal: true

class RequestIssueUpdateEvent < RequestIssuesUpdate


  class << self
    def process!(params)
      update_request_issues(params)
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewUpdatedRequestIssuesError, error.message
    end

    private


    # Compare and update the request issues associated with the decision review
    def update_request_issues(params)
      epe = params[:epe]
      parser = params[:parser]
      decision_review = params[:decision_review]
      existing_issues = decision_review.request_issues
      incoming_issues = parser.request_issues
      event = params[:event]

      # Process each incoming request issue
      incoming_issues.each do |incoming_issue|
        matching_issue = existing_issues.find { |issue| issue_matches?(issue, incoming_issue) }

        if matching_issue
          # If an existing issue matches the incoming one, update it
          update_existing_issue(matching_issue, incoming_issue, parser)
        else
          # If no match is found, create a new issue
          add_new_issue(incoming_issue, decision_review, parser)
        end
      end

      # Optionally, handle removal of issues not present in the incoming data
      remove_missing_issues(existing_issues, incoming_issues, event)
    end

    # Determine if an existing issue matches the incoming one (you may adjust this logic)
    def issue_matches?(existing_issue, incoming_issue)
      existing_issue.contention_reference_id == incoming_issue[:contention_reference_id]
    end

    def update_existing_issue(request_issue, incoming_issue, parser)
      request_issue.update!(
        benefit_type: incoming_issue[:benefit_type],
        contested_issue_description: incoming_issue[:contested_issue_description],
        contested_rating_issue_diagnostic_code: incoming_issue[:contested_rating_issue_diagnostic_code],
        decision_date: incoming_issue[:decision_date],
        closed_at: incoming_issue[:closed_at],
        closed_status: incoming_issue[:closed_status],
        contention_reference_id: incoming_issue[:contention_reference_id],
        end_product_establishment_id: parser.end_product_establishments_reference_id,
        updated_at: Time.current
      )
    end

    def add_new_issue(incoming_issue, decision_review, parser)
      RequestIssue.create!(
        benefit_type: incoming_issue[:benefit_type],
        contested_issue_description: incoming_issue[:contested_issue_description],
        contested_rating_issue_diagnostic_code: incoming_issue[:contested_rating_issue_diagnostic_code],
        decision_date: incoming_issue[:decision_date],
        contention_reference_id: incoming_issue[:contention_reference_id],
        decision_review: decision_review,
        end_product_establishment_id: parser.end_product_establishments_reference_id,
        veteran_participant_id: parser.veteran_participant_id,
        created_at: Time.current
      )
    end

    def remove_missing_issues(existing_issues, incoming_issues, event)
      incoming_ids = incoming_issues.map { |issue| issue[:id] }.compact

      existing_issues.each do |issue|
        unless incoming_ids.include?(issue.id)
          issue.update!(closed_at: Time.current, closed_status: 'removed')
          create_event_record(event, issue)
        end
      end
    end

    def create_event_record(event, issue)
      EventRecord.create!(event: event, evented_record: issue)
    end
  end


  #Trimed version of RequestIssuesUpdate

#   include Asyncable

#   belongs_to :user
#   belongs_to :review, polymorphic: true

#   attr_writer :request_issues_data
#   attr_reader :error_code

#   delegate :veteran, :cancel_active_tasks, :create_business_line_tasks!, to: :review
#   delegate :withdrawn_issues, to: :withdrawal
#   delegate :corrected_issues, :correction_issues, to: :correction

#   # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
#   def perform!(params)
#     event = params[:event]
#     parser = params[:parser] # Instance of DecisionReviewUpdatedParser
#     review = params[:decision_review]
#     epe = params[:epe]

#     return false unless validate_before_perform
#     return false if processed?

#     transaction do
#       process_issues!
#       review.mark_rating_request_issues_to_reassociate!
#       update!(
#         before_request_issue_ids: before_issues.map(&:id),
#         after_request_issue_ids: after_issues.map(&:id),
#         withdrawn_request_issue_ids: withdrawn_issues.map(&:id),
#         edited_request_issue_ids: edited_issues.map(&:id)
#       )
#       cancel_active_tasks
#       submit_for_processing!
#     end

#     process_job

#     true
#   end
#   # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

#   def process_job
#     if run_async?
#       DecisionReviewProcessJob.perform_later(self)
#     else
#       DecisionReviewProcessJob.perform_now(self)
#     end
#   end

#   # establish! is called async via DecisionReviewProcessJob.
#   # it is queued via submit_for_processing! in the perform! method above.
#   def establish!
#     attempted!

#     review.establish!
#     edited_issues.each { |issue| RequestIssueContention.new(issue).update_text! }
#     potential_end_products_to_remove = []
#     removed_or_withdrawn_issues.select(&:end_product_establishment).each do |request_issue|
#       RequestIssueContention.new(request_issue).remove!
#       potential_end_products_to_remove << request_issue.end_product_establishment
#     end

#     potential_end_products_to_remove.uniq.each(&:cancel_unused_end_product!)
#     clear_error!
#     processed!
#   end

#   def added_issues
#     after_issues - before_issues
#   end

#   def removed_issues
#     before_issues - after_issues
#   end

#   def removed_or_withdrawn_issues
#     removed_issues + withdrawn_issues
#   end

#   def before_issues
#     @before_issues ||= before_request_issue_ids ? fetch_before_issues : calculate_before_issues
#   end

#   def after_issues
#     @after_issues ||= after_request_issue_ids ? fetch_after_issues : calculate_after_issues
#   end

#   def edited_issues
#     @edited_issues ||= edited_request_issue_ids ? fetch_edited_issues : calculate_edited_issues
#   end

#   def all_updated_issues
#     added_issues + removed_issues + withdrawn_issues + edited_issues
#   end

#   def can_be_performed?
#     validate_before_perform
#   end

#   private

#   def changes?
#     all_updated_issues.any?
#   end

#   def calculate_after_issues
#     # need to calculate and store before issues before we add new request issues
#     before_issues

#     @request_issues_data.map do |issue_data|
#       request_issue = review.find_or_build_request_issue_from_intake_data(issue_data)

#       # If the data has a issue modification request id here, then add it in as an association
#       issue_modification_request_id = issue_data[:issue_modification_request_id]
#       if issue_modification_request_id && request_issue
#         issue_modification_request = IssueModificationRequest.find(issue_modification_request_id)
#         request_issue.issue_modification_requests << issue_modification_request
#       end

#       request_issue
#     end
#   end

#   def calculate_edited_issues
#     edited_issue_data.map do |issue_data|
#       review.find_or_build_request_issue_from_intake_data(issue_data)
#     end
#   end

#   def edited_issue_data
#     return [] unless @request_issues_data

#     @request_issues_data.select do |ri|
#       edited_issue?(ri)
#     end
#   end

#   def edited_issue?(request_issue)
#     (request_issue[:edited_description].present? || request_issue[:edited_decision_date].present?) &&
#       request_issue[:request_issue_id]
#   end

#   def calculate_before_issues
#     review.request_issues.active_or_ineligible.select(&:persisted?)
#   end

#   def validate_before_perform
#     if !changes?
#       @error_code = :no_changes
#     elsif RequestIssuesUpdate.where(review: review).where.not(id: id).processable.exists?
#       if @error_code == :no_changes
#         RequestIssuesUpdate.where(review: review).where.not(id: id).processable.last.destroy
#       end
#       @error_code = :previous_update_not_done_processing
#     end

#     !@error_code
#   end

#   def fetch_before_issues
#     RequestIssue.where(id: before_request_issue_ids)
#   end

#   def fetch_after_issues
#     RequestIssue.where(id: after_request_issue_ids)
#   end

#   def fetch_edited_issues
#     RequestIssue.where(id: edited_request_issue_ids)
#   end

#   def process_issues!
#     review.create_issues!(added_issues, self)
#     process_removed_issues!
#     process_legacy_issues!
#     process_withdrawn_issues!
#     process_edited_issues!
#   end

#   def process_legacy_issues!
#     LegacyOptinManager.new(decision_review: review).process!
#   end

#   def process_withdrawn_issues!
#     withdrawal.call
#   end

#   def withdrawal
#     @withdrawal ||= RequestIssueWithdrawal.new(
#       user: user,
#       request_issues_update: self,
#       request_issues_data: @request_issues_data
#     )
#   end

#   def process_edited_issues!
#     return if edited_issues.empty?

#     edited_issue_data.each do |edited_issue|
#       request_issue = RequestIssue.find(edited_issue[:request_issue_id].to_s)
#       edit_contention_text(edited_issue, request_issue)
#       edit_decision_date(edited_issue, request_issue)
#     end
#   end

#   def edit_contention_text(edited_issue_params, request_issue)
#     if edited_issue_params[:edited_description]
#       request_issue.save_edited_contention_text!(edited_issue_params[:edited_description])
#     end
#   end

#   def edit_decision_date(edited_issue_params, request_issue)
#     if edited_issue_params[:edited_decision_date]
#       request_issue.save_decision_date!(edited_issue_params[:edited_decision_date])
#     end
#   end

#   def process_removed_issues!
#     removed_issues.each(&:remove!)
#   end

#   # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
#   # :reek:FeatureEnvy
#   def create_issue_update_task(change_type, before_issue, after_issue = nil)
#     transaction do
#       # close out any tasks that might be open
#       open_issue_task = Task.where(
#         assigned_to: SpecialIssueEditTeam.singleton
#       ).where(status: "assigned").where(appeal: before_issue.decision_review)
#       open_issue_task[0].delete unless open_issue_task.empty?

#       task = IssuesUpdateTask.create!(
#         appeal: before_issue.decision_review,
#         parent: RootTask.find_by(appeal: before_issue.decision_review),
#         assigned_to: SpecialIssueEditTeam.singleton,
#         assigned_by: RequestStore[:current_user],
#         completed_by: RequestStore[:current_user]
#       )

#       # if a new issue is added and VBMS was edited, reference the original status
#       if change_type == "Added Issue"
#         set = CaseTimelineInstructionSet.new(
#           change_type: change_type,
#           issue_category: before_issue.contested_issue_description,
#           benefit_type: before_issue.benefit_type&.capitalize
#         )
#       else
#         # format the task instructions and close out
#         # use contested issue description if nonrating issue category is nil

#         issue_description = "#{before_issue.nonrating_issue_category} - #{before_issue.nonrating_issue_description}" unless before_issue.nonrating_issue_category.nil?
#         issue_description = before_issue.contested_issue_description if issue_description.nil?
#         set = CaseTimelineInstructionSet.new(
#           change_type: change_type,
#           issue_category: issue_description,
#           benefit_type: before_issue.benefit_type&.capitalize
#         )
#       end
#       task.format_instructions(set)
#       task.completed!

#       # create SpecialIssueChange record to log the changes
#       SpecialIssueChange.create!(
#         issue_id: before_issue.id,
#         appeal_id: before_issue.decision_review.id,
#         appeal_type: "Appeal",
#         task_id: task.id,
#         created_at: Time.zone.now.utc,
#         created_by_id: RequestStore[:current_user].id,
#         created_by_css_id: RequestStore[:current_user].css_id,
#         change_category: change_type
#       )
#     end
#   end
#   # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
# end
