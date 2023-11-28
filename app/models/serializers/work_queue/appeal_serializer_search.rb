# frozen_string_literal: true

class WorkQueue::AppealSerializerSearch
  include FastJsonapi::ObjectSerializer
  extend Helpers::AppealHearingHelper

  attribute :assigned_attorney
  attribute :assigned_judge

  attribute :current_user_timezone do |_, params|
    params[:user]&.timezone
  end

  attribute :contested_claim, &:contested_claim?

  attribute :issues do |object|
    object.request_issues.active_or_decided_or_withdrawn.includes(:remand_reasons).map do |issue|
      {
        id: issue.id,
        program: issue.benefit_type,
        description: issue.description,
        notes: issue.notes,
        diagnostic_code: issue.contested_rating_issue_diagnostic_code,
        remand_reasons: issue.remand_reasons,
        closed_status: issue.closed_status,
        decision_date: issue.decision_date
      }
    end
  end

  attribute :status

  attribute(:hearings) do |object, params|
    # For substitution appeals after death dismissal, we need to show hearings from the source appeal
    # in addition to those on the new/target appeal; this avoids copying them to new appeal stream
    associated_hearings = []

    if object.separate_appeal_substitution?
      associated_hearings = hearings(object.appellant_substitution.source_appeal, params)
    end

    associated_hearings + hearings(object, params)
  end

  attribute :appellant_is_not_veteran

  attribute :appellant_full_name do |object|
    object.claimant&.name
  end

  attribute :appellant_first_name do |object|
    object.claimant&.first_name
  end

  attribute :appellant_middle_name do |object|
    object.claimant&.middle_name
  end

  attribute :appellant_last_name do |object|
    object.claimant&.last_name
  end

  attribute :veteran_death_date

  attribute :veteran_file_number

  attribute :veteran_full_name do |object|
    object.veteran ? object.veteran.name.formatted(:readable_full) : "Cannot locate"
  end

  attribute :type
  attribute :vacate_type
  attribute :aod, &:advanced_on_docket?
  attribute :docket_name
  attribute :docket_number
  attribute :decision_date
  attribute :withdrawal_date

  attribute :caseflow_veteran_id do |object|
    object.veteran ? object.veteran.id : nil
  end
end
