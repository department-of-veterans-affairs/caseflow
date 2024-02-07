# frozen_string_literal: true

class CaseDistributionLever < ApplicationRecord
  has_many :case_distribution_audit_lever_entries, dependent: :delete_all
  validates :item, presence: true
  validates :title, presence: true
  validates :data_type, presence: true, inclusion: { in: Constants.ACD_LEVERS.data_types.to_h.values }
  validates :is_toggle_active, inclusion: { in: [true, false] }
  validates :is_disabled_in_ui, inclusion: { in: [true, false] }
  validate :value_matches_data_type

  self.table_name = "case_distribution_levers"
  INTEGER_LEVERS = %W(
    #{Constants.DISTRIBUTION.ama_direct_review_docket_time_goals}
    #{Constants.DISTRIBUTION.request_more_cases_minimum}
    #{Constants.DISTRIBUTION.alternative_batch_size}
    #{Constants.DISTRIBUTION.batch_size_per_attorney}
    #{Constants.DISTRIBUTION.days_before_goal_due_for_distribution}
    #{Constants.DISTRIBUTION.ama_hearing_case_affinity_days}
    #{Constants.DISTRIBUTION.cavc_affinity_days}
    #{Constants.DISTRIBUTION.ama_evidence_submission_docket_time_goals}
    #{Constants.DISTRIBUTION.ama_hearings_docket_time_goals}
  ).freeze

  FLOAT_LEVERS = %W(
    #{Constants.DISTRIBUTION.maximum_direct_review_proportion}
    #{Constants.DISTRIBUTION.minimum_legacy_proportion}
    #{Constants.DISTRIBUTION.nod_adjustment}
  ).freeze

  def distribution_value
    if data_type == Constants.ACD_LEVERS.data_types.radio
      option = options.detect { |opt| opt["item"] == value }
      option["value"] if option&.is_a?(Hash)
    else
      value
    end
  end

  private

  def value_matches_data_type
    case data_type
    when Constants.ACD_LEVERS.data_types.radio
      validate_options
    when Constants.ACD_LEVERS.data_types.number
      validate_number_data_type
    when Constants.ACD_LEVERS.data_types.boolean
      validate_boolean_data_type
    when Constants.ACD_LEVERS.data_types.combination
      validate_options
    end
  end

  def add_error_value_not_match_data_type
    errors.add(:value, "does not match its data_type #{data_type}. Value is #{value}")
  end

  def validate_options
    errors.add(:item, "is of #{data_type} and does not contain an options object") if options.nil?
  end

  def validate_number_data_type
    add_error_value_not_match_data_type if value&.match(/\A[0-9]*\.?[0-9]+\z/).nil?
    unless INTEGER_LEVERS.include?(item) || FLOAT_LEVERS.include?(item)
      errors.add(:item, "is of data_type number but is not included in INTEGER_LEVERS or FLOAT_LEVERS")
    end
  end

  def validate_boolean_data_type
    add_error_value_not_match_data_type if value&.match(/\A(t|true|f|false)\z/i).nil?
  end

  class << self
    def respond_to_missing?(name, _include_private)
      Constants.DISTRIBUTION.to_h.key?(name)
    end

    def method_missing(name, *args)
      if Constants.DISTRIBUTION.to_h.key?(name)
        value = method_missing_value(name.to_s)
        return value unless value.nil?
      end

      super
    end

    def update_acd_levers(current_levers, current_user)
      grouped_levers = current_levers.index_by { |lever| lever["id"] }
      previous_levers = CaseDistributionLever.where(id: grouped_levers.keys).index_by { |lever| lever["id"] }
      errors = []
      levers = []

      ActiveRecord::Base.transaction do
        levers = CaseDistributionLever.update(grouped_levers.keys, grouped_levers.values)

        unless levers.all?(&:valid?)
          errors = levers.select(&:invalid?).map { |lever| "Lever :#{lever.title} - #{lever.errors.full_messages}" }
        end
      end

      errors.concat(add_audit_lever_entries(previous_levers, levers, current_user))
    end

    private

    def method_missing_value(name)
      lever = find_by_item(name).try(:distribution_value)

      if INTEGER_LEVERS.include?(name)
        lever.to_i
      elsif FLOAT_LEVERS.include?(name)
        lever.to_f
      else
        lever
      end
    end

    def add_audit_lever_entries(previous_levers, levers, current_user)
      entries = []
      levers.filter(&:valid?).each do |lever|
        previous_lever = previous_levers[lever.id]
        entries.push({
                       user: current_user,
                       case_distribution_lever: lever,
                       previous_value: previous_lever.value,
                       update_value: lever.value
                     })
      end

      begin
        ActiveRecord::Base.transaction do
          CaseDistributionAuditLeverEntry.create(entries)
        end
      rescue StandardError => error
        return [error]
      end

      []
    end
  end
end
