# This job will retrieve cases from VACOLS via the AppealRepository
# and all documents for these cases in VBMS and store them
class RetrieveDocumentsForReaderJob < ActiveJob::Base
  queue_as :low_priority

  DEFAULT_DOCUMENTS_DOWNLOADED_LIMIT = 1500

  def perform(args = {})
    RequestStore.store[:application] = "reader"

    limit = args["limit"] || DEFAULT_DOCUMENTS_DOWNLOADED_LIMIT
    @counts = { docs_cached: 0, docs_failed: 0, appeals_successful: 0, appeals_failed: 0, consecutive_failures: 0 }

    find_all_active_reader_appeals.each do |user, appeals|
      RequestStore.store[:current_user] = user
      appeals.each { |appeal| start_fetch_job(appeal) }

      break if @counts[:docs_cached] >= limit || @counts[:consecutive_failures] >= 5
    end

    log_info
  end

  def start_fetch_job(appeal)
    FetchDocumentsForAppealJob.perform_now(appeal)
  end

  def find_all_active_reader_appeals
    User.where("'Reader' = ANY(roles)").reduce({}) do |active_appeals, user|
      active_appeals.update(user => user.current_case_assignments)
    end
  end

  def log_info
    output_msg = "RetrieveDocumentsForReaderJob successfully retrieved #{@counts[:docs_cached]} documents " \
          "for #{@counts[:appeals_successful]} appeals and #{@counts[:docs_failed]} document(s) failed.\n" \
          "Failed to retrieve documents for #{@counts[:appeals_failed]} appeal(s)."

    if @counts[:consecutive_failures] >= 5
      output_msg += "\nJob stopped after #{@counts[:consecutive_failures]} failures"
    end

    Rails.logger.info output_msg
    SlackService.new(url: slack_url).send_notification(output_msg)
  end

  def slack_url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end

end
