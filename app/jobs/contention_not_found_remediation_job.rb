# frozen_string_literal: true

# Job that will remediate ContentionNotFound Stuck Jobs
# This job may need to be run multiple times to fully remediate a Stuck Job
# since it is possible for more ContentionNotFound errors to occur after initial remediation
class ContentionNotFoundRemediationJob < CaseflowJob
  queue_with_priority :low_priority

  def initialize
    @logs = ["\nVBMS::ContentionNotFound Remediation Log"]
    @remediated_request_issues_update_ids = []
    super
  end

  # rubocop:disable all

  # Purpose: Find Request Issue Updates with ContentionNotFound Errors
  # and remove affected Edited Request Issue ID from Request Issues Update
  # so that DecisionReviewProcessJob can finish
  #
  # Params: None
  #
  # Returns: nil
  def perform
    RequestStore[:current_user] = User.system_user
    rius = find_contention_not_found_request_issues_updates
    total = rius.count
    Rails.logger.info("ContentionNotFoundRemediationJob::Log - Found #{total} ContentionNotFound Request Issues Updates")
    if total > 0
      contention_ids = get_contention_ids(rius)
      remediate!(rius, contention_ids, total)
      puts @logs
      store_logs_in_s3_bucket
    end
  end

  # Main method to loop through and remediate all CannotDeleteContention Request Issues Updates
  def remediate!(request_issues_updates, contention_ids, total)
    index = 0
    while index < total
      begin
        affected_request_issue = find_edited_request_issue(request_issues_updates[index], contention_ids[index])
        maybe_cancel_or_reprocess_request_issues_update!(affected_request_issue, request_issues_updates[index], index)
        sync_epe!(request_issues_updates[index], affected_request_issue, index)
        @remediated_request_issues_update_ids.push("RIU ID: #{request_issues_updates[index].id}, RI ID: #{affected_request_issue.id}")
        index += 1
      rescue StandardError => error
        @logs.push("#{Time.zone.now} ContentionNotFoundRemediation::Error - Number: #{index} "\
            " RIU ID: #{request_issues_updates[index].id}.  RI ID: #{affected_request_issue&.id}.  #{error.message}.")
        index += 1
        log_error(error)
        next
      end
    end
    remaining_ruis_w_error = find_contention_not_found_request_issues_updates
    @logs.push("\nCannotDeleteContentionRemediation::Log - Summary Report.  Total number of Request Issues Updates"\
    " with 'VBMS::CannotDeleteContention' error: #{total}.  Total number of Request Issues Updates"\
    " with attempted remediation: #{@remediated_request_issues_update_ids.count}.  Total number of Request Issues Updates"\
    " with VBMS::CannotDeleteContention errors remaining: #{remaining_ruis_w_error.count}.\n"\
    "IDs of request issues updates and correlated request issues with attempted remediation: ")
    @logs.push(@remediated_request_issues_update_ids)
  end

  # rubocop:enable all

  private

  # Find all Contention Not Found error Request Issues Updates
  def find_contention_not_found_request_issues_updates
    RequestIssuesUpdate.where("error LIKE ?", "%EndProductEstablishment::ContentionNotFound%")
      .merge(RequestIssuesUpdate.where(canceled_at: nil))
  end

  # Find all contention ids
  def get_contention_ids(request_issues_updates)
    request_issues_updates.map do |riu|
      riu.error.split("EndProductEstablishment::ContentionNotFound: ").second[/\d+/].to_i
    end
  end

  # Find affected Edited Request Issue using the Contention ID from the ContentionNotFound Error
  def find_edited_request_issue(request_issues_update, contention_id)
    affected_request_issue = request_issues_update.edited_issues.find do |ri|
      ri.contention_reference_id == contention_id
    end

    affected_request_issue
  end

  # Cancel the Request Issues Update
  def cancel_request_issues_update!(request_issue, request_issues_update, index)
    request_issues_update.canceled!
    @logs.push("#{Time.zone.now} ContentionNotFoundRemediation::Log - Number: #{index}"\
      " RIU ID: #{request_issues_update.id}.  RI ID: #{request_issue.id}.  Cancelling Request Issues Update.")
  end

  # Re-run Decision Review Process Job now that it is un-stuck
  def reprocess_request_issues_update!(request_issue, request_issues_update, index)
    DecisionReviewProcessJob.perform_now(request_issues_update)
    @logs.push("#{Time.zone.now} ContentionNotFoundRemediation::Log - Number: #{index}"\
      " RIU ID: #{request_issues_update.id}.  RI ID: #{request_issue.id}.  Reprocessing Request Issues Update.")
  end

  # Remove affected Request Issue ID from edited_request_issue_ids column
  def remove_edited_request_issue_id!(request_issue, request_issues_update, index)
    old_edited_ids = request_issues_update.edited_request_issue_ids
    new_edited_ids = (old_edited_ids - [request_issue.id])
    request_issues_update.update!(edited_request_issue_ids: new_edited_ids)
    @logs.push("#{Time.zone.now} ContentionNotFoundRemediation::Log - Number: #{index}"\
      " RIU ID: #{request_issues_update.id}.  RI ID: #{request_issue.id}."\
      "  Removing Request Issue ID #{request_issue.id} from Edited Issue IDs column.")
  end

  def update_and_reprocess_request_issues_update!(request_issue, request_issues_update, index)
    remove_edited_request_issue_id!(request_issue, request_issues_update, index)
    request_issues_update.instance_variable_set(:@edited_issues, nil)
    reprocess_request_issues_update!(request_issue, request_issues_update, index)
  end

  def maybe_cancel_or_reprocess_request_issues_update!(request_issue, request_issues_update, index)
    errant_edited_issues = [request_issue]
    if request_issues_update.all_updated_issues == errant_edited_issues
      cancel_request_issues_update!(request_issue, request_issues_update, index)
    else
      update_and_reprocess_request_issues_update!(request_issue, request_issues_update, index)
    end
  end

  # Reset End Product Establishment synced_status and re-sync with VBMS
  def sync_epe!(request_issues_update, request_issue, index)
    end_product_establishment = request_issue.end_product_establishment
    end_product = end_product_establishment.result
    prev_status = end_product_establishment.synced_status
    end_product_establishment.update!(synced_status: nil)
    end_product_establishment.sync!
    @logs.push("#{Time.zone.now} ContentionNotFoundRemediation::Log - Number: #{index}"\
      " RIU ID: #{request_issues_update.id}.  RI ID: #{request_issue.id}.  EPE ID: #{end_product_establishment.id}."\
      "  Previous EPE status: #{prev_status}.  EP status: #{end_product.status_type_code}."\
      "  Resetting EPE synced_status to null.  Syncing Epe with EP.")
  end

  # Save Logs to S3 Bucket
  def store_logs_in_s3_bucket
    # Set Client Resources for AWS
    Aws.config.update(region: "us-gov-west-1")
    s3client = Aws::S3::Client.new
    s3resource = Aws::S3::Resource.new(client: s3client)
    s3bucket = s3resource.bucket("data-remediation-output")

    # Folder and File name
    file_name = "contention-not-found-remediation-logs/cnf-remediation-log-#{Time.zone.now}"

    # Store contents of logs array in a temporary file
    content = @logs.join("\n")
    temporary_file = Tempfile.new("cnf-log.txt")
    filepath = temporary_file.path
    temporary_file.write(content)
    temporary_file.flush

    # Store File in S3 bucket
    s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256")

    # Delete Temporary File
    temporary_file.close!
  end
end
