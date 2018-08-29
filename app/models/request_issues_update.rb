# Represents the action where a Caseflow user updates the request issues on
# a review, typically to make a correction.

class RequestIssuesUpdate < ApplicationRecord
  belongs_to :user
  belongs_to :review, polymorphic: true

  attr_writer :request_issues_data
  attr_reader :error_code

  def perform!
    return false unless validate_before_perform

    transaction do
      # TODO: Investigate making each request issue responsible for determining its own
      # end product establishment. This will remove the need for the review to be responsible
      # for creating and removing the appropriate contentions
      new_issues.each(&:save!)

      strip_removed_issues!

      update!(
        before_request_issue_ids: before_issues.map(&:id),
        after_request_issue_ids: after_issues.map(&:id)
      )
    end

    review.on_request_issues_update!(self)

    true
  end

  def created_issues
    after_issues - before_issues
  end

  def removed_issues
    before_issues - after_issues
  end

  private

  def changes?
    review.request_issues.count != @request_issues_data.count || !new_issues.empty?
  end

  def new_issues
    after_issues.reject(&:persisted?)
  end

  def before_issues
    @before_issues ||= before_request_issue_ids ? fetch_before_issues : calculate_before_issues
  end

  def after_issues
    @after_issues ||= after_request_issue_ids ? fetch_after_issues : calculate_after_issues
  end

  def calculate_after_issues
    # need to calculate and store before issues before we add new request issues
    before_issues

    @request_issues_data.map do |issue_data|
      review.request_issues.find_or_initialize_by(
        rating_issue_profile_date: issue_data[:profile_date],
        rating_issue_reference_id: issue_data[:reference_id],
        description: issue_data[:description]
      )
    end
  end

  def calculate_before_issues
    review.request_issues.select(&:persisted?)
  end

  def validate_before_perform
    if !@request_issues_data || @request_issues_data.empty?
      @error_code = :request_issues_data_empty 
    elsif !changes?
      @error_code = :no_changes 
    end

    !@error_code
  end

  def fetch_before_issues
    RequestIssue.where(id: before_request_issue_ids)
  end

  def fetch_after_issues
    RequestIssue.where(id: after_request_issue_ids)
  end

  # Instead of fully deleting removed issues, we instead strip them from the review so we can
  # maintain a record of the other data that was on them incase we need to revert the update.
  def strip_removed_issues!
    removed_issues.each { |issue| issue.update!(review_request: nil) }
  end
end
