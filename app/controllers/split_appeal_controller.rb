# If you are using a Many-to-Many relationship, 
# you may tell amoeba to actually make duplicates 
# of the original related records rather than merely 
# maintaining association with the original records. 
# Cloning is easy, merely tell amoeba which fields to 
# clone in the same way you tell it which fields to include or exclude.

# This example will actually duplicate the warnings and widgets 
# in the database. If there were originally 3 warnings in the database then, 
# upon duplicating a post, you will end up with 6 warnings in the database. 
# This is in contrast to the default behavior where your new post would 
# merely be re-associated with any previously existing warnings and those 
# warnings themselves would not be duplicate.

# Configure your models with one of the styles below and then just run 
# the amoeba_dup method on your model where you would run the dup method normally:
# p = Post.create(:title => "Hello World!", :content => "Lorum ipsum dolor")
# p.comments.create(:content => "I love it!")
# p.comments.create(:content => "This sucks!")
# puts Comment.all.count # should be 2

# my_copy = p.amoeba_dup
# my_copy.save
# By default, when enabled, amoeba will copy any and all associated 
# child records automatically and associate them with the new parent record.
# You can configure the behavior to only include fields that you list or 
# to only include fields that you don't exclude. 
# puts Comment.all.count # should be 4

# This could potential help us Identify where duplicates are located in the database.
# Make a record query

# frozen_string_literal: true

# p = Post.create(:title => "Hello World!", :content => "Lorum ipsum dolor")
# p.comments.create(:content => "I love it!")
# p.comments.create(:content => "This sucks!")
# puts Comment.all.count # should be 2

# my_copy = p.amoeba_dup
# my_copy.save
# By default, when enabled, amoeba will copy any and all associated 

class SplitAppealController < ApplicationController
  before_action :react_routed
  has_many :ama_decision_issues, -> { includes(:ama_decision_documents).references(:decision_documents) },
  include BelongsToPolymorphicAppealConcern
  include UpdatedByUserConcern

  belongs_to :created_by, class_name: "User"
  belongs_to :source_appeal, class_name: "Appeal"
  belongs_to :split_appeal, class_name: "Appeal"

  def decision_issues
    ama_decision_issues if appeal_type == "Appeal"
    # LegacyAppeals do not have decision_issue records
  end

  def document_type
    "BVA Decision"
  end

  def source
    "BVA"
  end

  # We have to always download the file from s3 to make sure it exists locally
  # instead of storing it on the server and relying that it will be there
  def pdf_location
    S3Service.fetch_file(s3_location, output_location)
    output_location
  end

  def submit_for_processing!(delay: processing_delay)
    update_decision_issue_decision_dates! if appeal.is_a?(Appeal)

    cache_file!
    super

    if not_processed_or_decision_date_not_in_the_future?
      ProcessDecisionDocumentJob.perform_later(id)
    end
  end

  def process!
    return if processed?
    
    fail NotYetSubmitted unless submitted_and_ready?

    attempted!
    upload_to_vbms!

    if appeal.is_a?(Appeal)
      Appeal = find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id
      #Change code method here
      fail NotImplementedError if appeal.claimant.is_a?(OtherClaimant)
      # We do not want to process Board Grant Effectuations or create remand supplemental claims
      # Impliment
      p = appeal.create(:title => "Hello World!", :content => "Lorum ipsum dolor")
      appeal_copy = p.amoeba_dup
      appeal_copy.save
      p.save
      puts ("p")
    end
    processed!
  rescue StandardError => error
    update_error!(error.to_s)
    raise error
  end

  # Used by EndProductEstablishment to determine what modifier to use for the effectuation EPs
  def valid_modifiers
    HigherLevelReview::END_PRODUCT_MODIFIERS
  end

  def invalid_modifiers
    []
  end

  # The decision document is the source for all board grant eps, so we define this method
  # to be called any time a corresponding board grant end product change statuses.
  def on_sync(end_product_establishment)
    end_product_establishment.sync_decision_issues! if end_product_establishment.status_cleared?
  end

  def contention_records(epe)
    effectuations.where(end_product_establishment: epe)
  end

  def all_contention_records(epe)
    contention_records(epe)
  end
  
  before_action :set_application, only: [:document_count, :power_of_attorney, :update_power_of_attorney]
  # Only whitelist endpoints VSOs should have access to.
  # Probably need to allow user access here.
  skip_before_action :deny_vso_access, only: [
    :index,
    :power_of_attorney,
    :show_case_list,
    :show,
    :veteran,
    :most_recent_hearing
  ]

  #It's Json
  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        case_search = request.headers["HTTP_CASE_SEARCH"]
        # Began with the result change here.
        result = if docket_number?(case_search)
                  CaseSearchResultsForDocketNumber.new(
                    docket_number: case_search, user: current_user
                  ).call
                else
                  CaseSearchResultsForVeteranFileNumber.new(
                    file_number_or_ssn: case_search, user: current_user
                  ).call
                end

        render_search_results_as_json(result)
      end
    end
  end

  def show_case_list
    #change to show list of info
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        result = CaseSearchResultsForCaseflowVeteranId.new(
          caseflow_veteran_ids: params[:veteran_ids]&.split(","), user: current_user
        ).call

        render_search_results_as_json(result)
      end
    end
  end

  def document_count
    #Checks efolder access & doc count.
    doc_count = EFolderService.document_count(appeal.veteran_file_number, current_user)
    status = (doc_count == ::ExternalApi::EfolderService::DOCUMENT_COUNT_DEFERRED) ? 202 : 200
    render json: { document_count: doc_count }, status: status
  rescue Caseflow::Error::EfolderAccessForbidden => error
    render(error.serialize_response)
  rescue StandardError => error
    handle_non_critical_error("document_count", error)
  end
  #Can rendor the power of attorney data
  def power_of_attorney
    render json: power_of_attorney_data
  end
  #Updates the POA
  def update_power_of_attorney
    clear_poa_not_found_cache
    if cooldown_period_remaining > 0
      render json: {
        alert_type: "info",
        message: "Information is current at this time. Please try again in #{cooldown_period_remaining} minutes",
        power_of_attorney: power_of_attorney_data
      }
    else
      message, result, status = update_or_delete_power_of_attorney!
      render json: {
        alert_type: result,
        message: message,
        power_of_attorney: (status == "updated") ? power_of_attorney_data : {}
      }
    end
  rescue StandardError => error
    render_error(error)
  end
  #Check on the most recent Hearing?
  def most_recent_hearing
    most_recently_held_hearing = HearingsForAppeal.new(url_appeal_uuid)
      .held_hearings
      .max_by(&:scheduled_for)

    render json:
      if most_recently_held_hearing
        AppealHearingSerializer.new(most_recently_held_hearing,
                                    params: { user: current_user }).serializable_hash[:data][:attributes]
      else
        {}
      end
  end

  # For legacy appeals, veteran address and birth/death dates are
  # the only data that is being pulled from BGS, the rest are from VACOLS for now
  def veteran
    render json: {
      veteran: ::WorkQueue::VeteranSerializer.new(
        appeal,
        params: { relationships: params["relationships"] }
      ).serializable_hash[:data][:attributes]
    }
  end

  def show
    no_cache
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        if appeal.accessible?
          id = params[:appeal_id]
          MetricsService.record("Get appeal information for ID #{id}",
                                service: :queue,
                                name: "AppealsController.show") do
            appeal.appeal_views.find_or_create_by(user: current_user).update!(last_viewed_at: Time.zone.now)

            render json: { appeal: json_appeals(appeal)[:data] }
          end
        else
          render_access_error
        end
      end
    end
  end

  def edit
    # only AMA appeals may call /edit
    return not_found if appeal.is_a?(LegacyAppeal)
  end

  helper_method :appeal, :url_appeal_uuid

  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def url_appeal_uuid
    params[:appeal_id]
  end

  def update
    if request_issues_update.perform!
      set_flash_success_message

      render json: {
        beforeIssues: request_issues_update.before_issues.map(&:serialize),
        afterIssues: request_issues_update.after_issues.map(&:serialize),
        withdrawnIssues: request_issues_update.withdrawn_issues.map(&:serialize)
      }
    else
      render json: { error_code: request_issues_update.error_code }, status: :unprocessable_entity
    end
  end

  private

  # :reek:DuplicateMethodCall { allow_calls: ['result.extra'] }
  # :reek:FeatureEnvy
  def render_search_results_as_json(result)
    if result.success?
      render json: result.extra[:search_results]
    else
      render json: result.to_h, status: result.extra[:status]
    end
  end

  def request_issues_update
    @request_issues_update ||= RequestIssuesUpdate.new(
      user: current_user,
      review: appeal,
      request_issues_data: params[:request_issues]
    )
  end

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def json_appeals(appeal)
    if appeal.is_a?(Appeal)
      WorkQueue::AppealSerializer.new(appeal, params: { user: current_user }).serializable_hash
    else
      WorkQueue::LegacyAppealSerializer.new(appeal, params: { user: current_user }).serializable_hash
    end
  end

  def review_removed_message
    claimant_name = appeal.veteran_full_name
    "You have successfully removed #{appeal.class.review_title} for #{claimant_name}
    (ID: #{appeal.veteran_file_number})."
  end

  def review_withdrawn_message
    "You have successfully withdrawn a review."
  end

  def withdrawn_issues
    withdrawn = request_issues_update.withdrawn_issues

    return if withdrawn.empty?

    "withdrawn #{withdrawn.count} #{'issue'.pluralize(withdrawn.count)}"
  end

  def added_issues
    new_issues = request_issues_update.after_issues - request_issues_update.before_issues
    return if new_issues.empty?

    "added #{new_issues.count} #{'issue'.pluralize(new_issues.count)}"
  end

  def removed_issues
    removed = request_issues_update.before_issues - request_issues_update.after_issues

    return if removed.empty?

    "removed #{removed.count} #{'issue'.pluralize(removed.count)}"
  end

  def review_edited_message
    "You have successfully " + [added_issues, removed_issues, withdrawn_issues].compact.to_sentence + "."
  end

  def set_flash_success_message
    flash[:edited] = if request_issues_update.after_issues.empty?
                      review_removed_message
                    elsif (request_issues_update.after_issues - request_issues_update.withdrawn_issues).empty?
                      review_withdrawn_message
                    else
                      review_edited_message
                    end
  end

  def render_access_error
    render(Caseflow::Error::ActionForbiddenError.new(
      message: access_error_message
    ).serialize_response)
  end

  def access_error_message
    appeal.veteran&.multiple_phone_numbers? ? COPY::DUPLICATE_PHONE_NUMBER_TITLE : COPY::ACCESS_DENIED_TITLE
  end

  def docket_number?(search)
    !search.nil? && search.match?(/\d{6}-{1}\d+$/)
  end

  def update_or_delete_power_of_attorney!
    appeal.power_of_attorney&.try(:clear_bgs_power_of_attorney!) # clear memoization on legacy appeals
    poa = appeal.bgs_power_of_attorney

    if poa.blank?
      ["Successfully refreshed. No power of attorney information was found at this time.", "success", "blank"]
    elsif poa.bgs_record == :not_found
      poa.destroy!
      ["Successfully refreshed. No power of attorney information was found at this time.", "success", "deleted"]
    else
      poa.save_with_updated_bgs_record!
      ["POA Updated Successfully", "success", "updated"]
    end
  end

  def power_of_attorney_data
    {
      representative_type: appeal.representative_type,
      representative_name: appeal.representative_name,
      representative_address: appeal.representative_address,
      representative_email_address: appeal.representative_email_address,
      representative_tz: appeal.representative_tz,
      poa_last_synced_at: appeal.poa_last_synced_at
    }
  end

  def clear_poa_not_found_cache
    Rails.cache.delete("bgs-participant-poa-not-found-#{appeal&.veteran&.file_number}")
    Rails.cache.delete("bgs-participant-poa-not-found-#{appeal&.claimant_participant_id}")
  end

  def cooldown_period_remaining
    next_update_allowed_at = appeal.poa_last_synced_at + 10.minutes if appeal.poa_last_synced_at.present?
    if next_update_allowed_at && next_update_allowed_at > Time.zone.now
      return ((next_update_allowed_at - Time.zone.now) / 60).ceil
    end

    0
  end

  def render_error(error)
    Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
    Raven.capture_exception(error, extra: { appeal_type: appeal.type, appeal_id: appeal.id })
    render json: {
      alert_type: "error",
      message: "Something went wrong"
    }, status: :unprocessable_entity
  end
end
