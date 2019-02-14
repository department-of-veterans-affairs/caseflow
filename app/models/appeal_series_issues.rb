class AppealSeriesIssues
  include ActiveModel::Model

  attr_accessor :appeal_series

  delegate :appeals, to: :appeal_series

  ELIGIBLE_TYPES = ["Original", "Post Remand", "Court Remand"].freeze

  LAST_ACTION_TYPE_FOR_DISPOSITIONS = {
    allowed: [
      :allowed
    ],
    denied: [
      :denied
    ],
    remand: [
      :remanded,
      :manlincon_remand
    ],
    field_grant: [
      :benefits_granted_by_aoj,
      :advance_allowed_in_field
    ],
    withdrawn: [
      :withdrawn,
      :motion_to_vacate_withdrawn,
      :withdrawn_from_remand,
      :recon_motion_withdrawn,
      :advance_withdrawn_by_appellant_rep,
      :advance_failure_to_respond,
      :remand_failure_to_respond,
      :ramp_opt_in
    ]
  }.freeze

  def all
    unmerged_issues_with_cavc_decisions_preloaded
      .select(&:codes?)
      .group_by(&:type_hash)
      .map do |_type_hash, issues|
        last_action = last_action_for_issues(issues)
        active = issues.any?(&:active?) || last_action[:type] == :remand || last_action[:type] == :cavc_remand

        {
          description: issues.first.friendly_description,
          diagnostic_code: issues.first.diagnostic_code,
          active: active,
          last_action: last_action[:type],
          date: last_action[:date].try(:to_date)
        }
      end
  end

  private

  def unmerged_issues_with_cavc_decisions_preloaded
    appeals.flat_map do |appeal|
      next [] unless ELIGIBLE_TYPES.include? appeal.type

      appeal.issues.reject(&:merged?).each do |issue|
        issue.appeal = appeal
        issue.cavc_decisions = appeal.cavc_decisions.select do |cavc_decision|
          cavc_decision.issue_vacols_sequence_id == issue.vacols_sequence_id
        end
      end
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def last_action_for_issues(issues)
    issues.reduce(date: nil, type: nil) do |memo, issue|
      if issue.close_date && (memo[:date].nil? || issue.close_date > memo[:date])
        type = last_action_type_from_disposition(issue.disposition)

        if type
          # Prevent draft decisions from being shared publicly
          unless [:allowed, :denied, :remand].include?(type) && issue.appeal.activated?
            memo[:date] = issue.close_date
            memo[:type] = type
          end
        end
      end

      last_cavc_remand = issue.cavc_decisions.select(&:remanded?).max_by(&:decision_date)

      if last_cavc_remand && (memo[:date].nil? || last_cavc_remand.decision_date > memo[:date])
        memo[:date] = last_cavc_remand.decision_date
        memo[:type] = :cavc_remand
      end

      memo
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def last_action_type_from_disposition(disposition)
    LAST_ACTION_TYPE_FOR_DISPOSITIONS.keys.find do |type|
      LAST_ACTION_TYPE_FOR_DISPOSITIONS[type].include?(disposition)
    end
  end
end
