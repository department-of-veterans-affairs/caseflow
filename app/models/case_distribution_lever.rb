# frozen_string_literal: true

class CaseDistributionLever < ApplicationRecord
  has_many :case_distribution_audit_lever_entries, dependent: :delete_all
  validates :item, presence: true
  validates :title, presence: true
  validates :data_type, presence: true, inclusion: { in: Constants.ACD_LEVERS.data_types.to_h.values }
  validates :is_toggle_active, inclusion: { in: [true, false, nil] }
  validates :is_disabled_in_ui, inclusion: { in: [true, false] }
  validate :value_matches_data_type

  scope :enabled_in_ui, -> { where(is_disabled_in_ui: false) }

  self.table_name = "case_distribution_levers"
  INTEGER_LEVERS = %W(
    #{Constants.DISTRIBUTION.ama_direct_review_docket_time_goals}
    #{Constants.DISTRIBUTION.request_more_cases_minimum}
    #{Constants.DISTRIBUTION.alternative_batch_size}
    #{Constants.DISTRIBUTION.batch_size_per_attorney}
    #{Constants.DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals}
    #{Constants.DISTRIBUTION.ama_hearing_case_affinity_days}
    #{Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days}
    #{Constants.DISTRIBUTION.cavc_affinity_days}
    #{Constants.DISTRIBUTION.cavc_aod_affinity_days}
    #{Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days}
    #{Constants.DISTRIBUTION.ama_evidence_submission_docket_time_goals}
    #{Constants.DISTRIBUTION.ama_hearing_docket_time_goals}
    #{Constants.DISTRIBUTION.ama_hearing_start_distribution_prior_to_goals}
    #{Constants.DISTRIBUTION.ama_evidence_submission_start_distribution_prior_to_goals}
    #{Constants.DISTRIBUTION.nonsscavlj_number_of_appeals_to_move}
  ).freeze

  FLOAT_LEVERS = %W(
    #{Constants.DISTRIBUTION.maximum_direct_review_proportion}
    #{Constants.DISTRIBUTION.minimum_legacy_proportion}
    #{Constants.DISTRIBUTION.nod_adjustment}
  ).freeze

  BOOLEAN_LEVERS = %W(
    #{Constants.DISTRIBUTION.disable_legacy_priority}
    #{Constants.DISTRIBUTION.disable_legacy_non_priority}
  ).freeze

  def history_value
    if combination_lever?
      combination_value
    elsif radio_lever?
      radio_value
    else
      value
    end
  end

  def combination_lever?
    data_type == Constants.ACD_LEVERS.data_types.combination
  end

  def radio_lever?
    data_type == Constants.ACD_LEVERS.data_types.radio
  end

  def omit?
    return false unless radio_lever?

    value == Constants.ACD_LEVERS.omit
  end

  def infinite?
    return false unless radio_lever?

    value == Constants.ACD_LEVERS.infinite
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
      validate_combination_data_type
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

  def validate_combination_data_type
    errors.add(:item, "is of #{data_type} and does not contain a valid is_toggle_active value") if is_toggle_active.nil?
    validate_options
  end

  # this matches what is displayed in frontend
  # see client/app/caseDistribution/components/SaveModal.jsx
  def combination_value
    toggle_string = is_toggle_active ? "Active" : "Inactive"
    "#{toggle_string} - #{value}"
  end

  def option(item)
    options&.find { |option| option["item"] == item } || {}
  end

  # this matches what is displayed in frontend
  # see client/app/caseDistribution/components/SaveModal.jsx
  def radio_value
    return option(value)["text"] if [Constants.ACD_LEVERS.omit, Constants.ACD_LEVERS.infinite].include?(value.to_s)

    selected_option = option(Constants.ACD_LEVERS.value)

    "#{selected_option['text']} #{value}"
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

      # if lever is a radio update options object
      grouped_levers.each_pair do |lever_id, lever|
        previous_lever = previous_levers[lever_id]
        next unless previous_lever.radio_lever?

        # update options
        update_radio_options(lever, previous_lever.options)
      end

      ActiveRecord::Base.transaction do
        levers = CaseDistributionLever.update(grouped_levers.keys, grouped_levers.values)

        unless levers.all?(&:valid?)
          errors = levers.select(&:invalid?).map { |lever| "Lever :#{lever.title} - #{lever.errors.full_messages}" }
        end
      end

      errors.concat(add_audit_lever_entries(previous_levers, levers, current_user))
    end

    # Map active levers (enabled in UI) into a hash object
    # Hash object has better formatting than an array when looking values in rails console
    def snapshot
      snapshot_hash = {}

      CaseDistributionLever.all.each_with_object(snapshot_hash) do |lever, s_hash|
        s_hash[lever.item] = {
          value: lever.value,
          is_toggle_active: lever.is_toggle_active
        }
      end

      snapshot_hash
    end

    private

    def method_missing_value(name)
      lever = find_by_item(name).try(:value)
      begin
        if INTEGER_LEVERS.include?(name)
          Integer(lever)
        elsif FLOAT_LEVERS.include?(name)
          Float(lever)
        elsif BOOLEAN_LEVERS.include?(name)
          ActiveModel::Type::Boolean.new.cast(lever)
        else
          lever
        end
      rescue ArgumentError
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
                       previous_value: previous_lever.history_value,
                       update_value: lever.history_value
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

    # Modified by reference the lever and options objects and then add
    # lever["options"] so that CaseDistributionLever.update updates the options field
    def update_radio_options(lever, options)
      selected_option = if [Constants.ACD_LEVERS.omit, Constants.ACD_LEVERS.infinite].include?(lever["value"])
                          lever["value"]
                        else
                          Constants.ACD_LEVERS.value
                        end

      options.each do |option|
        option["selected"] = option["item"] == selected_option

        if option["selected"] && option["item"] == Constants.ACD_LEVERS.value
          option["value"] = lever["value"].to_i
        end
      end

      lever["options"] = options
    end
  end
end
