# frozen_string_literal: true

# Job that will remediate CannotDeleteContention Stuck Jobs
# This job may need to be run multiple times to fully remediate a Stuck Job
# since it is possible for more CannotDeleteContention errors to occur after initial remediation
class CannotDeleteContentionRemediationJob < CaseflowJob
  queue_with_priority :low_priority

  def initialize
    @logs = ["\nVBMS::CannotDeleteContention Remediation Log"]
    @remediated_request_issues_update_ids = []
    super
  end

  # rubocop:disable all

  # Purpose: Find Request Issue Updates with CannotDeleteContention Errors
  # and un-remove/un-withdraw affected Request Issue from Request Issues Update
  # so that DecisionReviewProcessJob can finish
  #
  # Params: None
  #
  # Returns: nil
  def perform
    RequestStore[:current_user] = User.system_user
    rius = find_cannot_delete_contention_request_issues_updates
    total = rius.count
    Rails.logger.info("CannotDeleteContentionRemediationJob::Log - Found #{total} CannotDeleteContention Request Issues Updates")
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
        affected_request_issue = find_removed_or_withdrawn_request_issue(request_issues_updates[index], contention_ids[index])
        reset_ri_closed_status_and_closed_at!(affected_request_issue, request_issues_updates[index], index)
        maybe_cancel_or_reprocess_request_issues_update!(affected_request_issue, request_issues_updates[index], index)
        sync_epe!(request_issues_updates[index], affected_request_issue, index)
        @remediated_request_issues_update_ids.push("RIU ID: #{request_issues_updates[index].id}, RI ID: #{affected_request_issue.id}")
        index += 1
      rescue StandardError => error
        @logs.push("#{Time.zone.now} CannotDeleteContentionRemediation::Error - Number: #{index} "\
            " RIU ID: #{request_issues_updates[index].id}.  RI ID: #{affected_request_issue&.id}.  #{error.message}.")
        log_error(error)
        index += 1
        next
      end
    end
    remaining_ruis_w_error = find_cannot_delete_contention_request_issues_updates
    @logs.push("\nCannotDeleteContentionRemediation::Log - Summary Report.  Total number of Request Issues Updates"\
    " with 'VBMS::CannotDeleteContention' error: #{total}.  Total number of Request Issues Updates"\
    " with attempted remediation: #{@remediated_request_issues_update_ids.count}.  Total number of Request Issues Updates"\
    " with VBMS::CannotDeleteContention errors remaining: #{remaining_ruis_w_error.count}.\n"\
    "IDs of request issues updates and correlated request issues with attempted remediation: ")
    @logs.push(@remediated_request_issues_update_ids)
  end

  # rubocop:enable all

  private

  # Find all Cannot Delete Contention error Request Issues Updates
  def find_cannot_delete_contention_request_issues_updates
    RequestIssuesUpdate.where("error LIKE ?", "%VBMS::CannotDeleteContention%")
      .merge(RequestIssuesUpdate.where(canceled_at: nil))
  end

  # Find all contention ids
  def get_contention_ids(request_issues_updates)
    request_issues_updates.map do |riu|
      riu.error.split("VBMS::Responses::Contention id").second[/\d+/].to_i
    end
  end

  # Find affected Request Issue using the contention id from the Cannot Delete Contention Error
  def find_removed_or_withdrawn_request_issue(request_issues_update, contention_id)
    affected_request_issue = request_issues_update.removed_or_withdrawn_issues.find do |ri|
      ri.contention_reference_id == contention_id
    end

    affected_request_issue
  end

  # Resets closed_at and closed_status values to nil
  def reset_ri_closed_status_and_closed_at!(request_issue, request_issues_update, index)
    prev_closed_status = request_issue.closed_status
    prev_closed_at = request_issue.closed_at
    request_issue.update!(closed_status: nil, closed_at: nil)
    @logs.push("#{Time.zone.now} CannotDeleteContentionRemediation::Log - Number: #{index}"\
      " RIU ID: #{request_issues_update.id}.  RI ID: #{request_issue.id}."\
      "  Setting the Request Issue closed_status & closed_at to null."\
      "  Previous closed_status was #{prev_closed_status}.  Previous closed_at was #{prev_closed_at}.")
  end

  # Cancel the Request Issues Update
  def cancel_request_issues_update!(request_issue, request_issues_update, index)
    request_issues_update.canceled!
    @logs.push("#{Time.zone.now} CannotDeleteContentionRemediation::Log - Number: #{index} "\
      "RIU ID: #{request_issues_update.id}.  RI ID: #{request_issue.id}.  Cancelling Request Issues Update.")
  end

  # Re-run Decision Review Process Job now that it is un-stuck
  def reprocess_request_issues_update!(request_issue, request_issues_update, index)
    DecisionReviewProcessJob.perform_now(request_issues_update)
    @logs.push("#{Time.zone.now} CannotDeleteContentionRemediation::Log - Number: #{index} "\
      "RIU ID: #{request_issues_update.id}.  RI ID: #{request_issue.id}.  Reprocessing Request Issues Update.")
  end

  # Add affected Request Issue ID back to after_request_issue_ids column
  def unremove_request_issue!(request_issue, request_issues_update, index)
    new_after_issue_ids = request_issues_update.after_request_issue_ids.push(request_issue.id)
    request_issues_update.update!(after_request_issue_ids: new_after_issue_ids)
    request_issues_update.instance_variable_set(:@after_issues, nil)
    @logs.push("#{Time.zone.now} CannotDeleteContentionRemediation::Log - Number: #{index}"\
      " RIU ID: #{request_issues_update.id}.  RI ID: #{request_issue.id}.  Un-removing Request Issue"\
      " ID: #{request_issue.id}.")
  end

  # Remove affected Request Issue ID from withdrawn_issue_ids column
  def unwithdraw_request_issue!(request_issue, request_issues_update, index)
    new_withdrawn_issues_ids = request_issues_update.withdrawn_request_issue_ids - [request_issue.id]
    request_issues_update.update!(withdrawn_request_issue_ids: new_withdrawn_issues_ids)
    request_issues_update.instance_variable_set(:@withdrawal, nil)
    @logs.push("#{Time.zone.now} CannotDeleteContentionRemediation::Log - Number: #{index}"\
      " RIU ID: #{request_issues_update.id}.  RI ID: #{request_issue.id}.  Un-withdrawing Request Issue"\
      " ID: #{request_issue.id}.")
  end

  # Method that will either un-remove or un-withdraw affected Request Issue ID from Request Issues Update
  def update_and_reprocess_request_issues_update!(request_issue, request_issues_update, index)
    if request_issues_update.withdrawn_issues.include?(request_issue)
      unwithdraw_request_issue!(request_issue, request_issues_update, index)
    elsif request_issues_update.removed_issues.include?(request_issue)
      unremove_request_issue!(request_issue, request_issues_update, index)
    end
    reprocess_request_issues_update!(request_issue, request_issues_update, index)
  end

  # Method that will cancel Request Issues Update if only change is related to affected Request Issue
  # If it includes other changes, update the Request Issues Update and re-process the job
  def maybe_cancel_or_reprocess_request_issues_update!(request_issue, request_issues_update, index)
    if request_issues_update.all_updated_issues == [request_issue]
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
    @logs.push("#{Time.zone.now} CannotDeleteContentionRemediation::Log - Number: #{index}"\
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
    file_name = "cannot-delete-contention-remediation-logs/cdc-remediation-log-#{Time.zone.now}"

    # Store contents of logs array in a temporary file
    content = @logs.join("\n")
    temporary_file = Tempfile.new("cdc-log.txt")
    filepath = temporary_file.path
    temporary_file.write(content)
    temporary_file.flush

    # Store File in S3 bucket
    s3bucket.object(file_name).upload_file(filepath, acl: "private", server_side_encryption: "AES256")

    # Delete Temporary File
    temporary_file.close!
  end
end
