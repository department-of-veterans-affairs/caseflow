class CaseDistributionLever < ApplicationRecord

  validates :item, presence: true
  validates :title, presence: true
  validates :data_type, presence: true
  validates :value, presence: true, if: Proc.new { |lever| lever.data_type != Constants.ACD_LEVERS.number }
  validates :is_toggle_active, inclusion: { in: [true, false] }
  validates :is_disabled_in_ui, inclusion: { in: [true, false] }

  self.table_name = "case_distribution_levers"
  INTEGER_LEVERS = %W(
    #{Constants.DISTRIBUTION.ama_direct_review_docket_time_goals}
    #{Constants.DISTRIBUTION.request_more_cases_minimum}
    #{Constants.DISTRIBUTION.alternative_batch_size}
    #{Constants.DISTRIBUTION.batch_size_per_attorney}
    #{Constants.DISTRIBUTION.days_before_goal_due_for_distribution}
    #{Constants.DISTRIBUTION.ama_hearing_case_affinity_days}
    #{Constants.DISTRIBUTION.cavc_affinity_days}
  )
  FLOAT_LEVERS = %W(
    #{Constants.DISTRIBUTION.maximum_direct_review_proportion}
    #{Constants.DISTRIBUTION.minimum_legacy_proportion}
    #{Constants.DISTRIBUTION.nod_adjustment}
  )

  def update_levers(lever_list)
    lever_list.each do |updated_lever|
      updated_lever.save!
    end
  end

  def distribution_value
    if self.data_type == Constants.ACD_LEVERS.radio
      option = self.options.detect{|opt| opt['item'] == self.value}
      option['value'] if option && option.is_a?(Hash)
    else
      self.value
    end
  end

  class << self
    def find_integer_lever(lever)
      # binding.pry
      return 0 unless INTEGER_LEVERS.include?(lever)
      CaseDistributionLever.find_by_item(lever).try(:distribution_value).to_i
    end

    def find_float_lever(lever)
      # binding.pry
      return 0 unless FLOAT_LEVERS.include?(lever)
      CaseDistributionLever.find_by_item(lever).try(:distribution_value).to_f
    end
  end

  def update_acd_levers(current_levers)
    grouped_levers = current_levers.index_by { |lever| lever["id"] }
    prevous_levers = CaseDistributionLever.where(id: grouped_levers.keys).index_by { |lever| lever["id"] }
    errors = []

    ActiveRecord::Base.transaction do
      levers = CaseDistributionLever.update(grouped_levers.keys, grouped_levers.values)

      unless levers.all?(&:changed?)
        errors = levers.select(&:invalid?).map { |lever| "Lever :#{lever.title} - #{lever.errors.full_messages}" }.join("<br/>")
      end
    end

    errors.concat(add_audit_lever_entries(previous_levers, levers))
  end

  def add_audit_lever_entries(previous_levers, levers)
    entries = []
    levers.each do |lever|
      previous_lever = previous_levers[lever.id]
      entries.push ({
        user: current_user,
        case_distribution_lever: lever,
        user_name: current_user.css_id,
        title: lever.title,
        previous_value: entry_data["original_value"],
        update_value: entry_data["current_value"],
        created_at: entry_data["created_at"]

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

  def format_audit_lever_entries(audit_lever_entries_data)
    formatted_audit_lever_entries = []

    begin
      audit_lever_entries_data.each do |entry_data|
        lever = CaseDistributionLever.find_by_title entry_data["lever_title"]

        formatted_audit_lever_entries.push ({
          user: current_user,
          case_distribution_lever: lever,
          user_name: current_user.css_id,
          title: lever.title,
          previous_value: entry_data["original_value"],
          update_value: entry_data["current_value"],
          created_at: entry_data["created_at"]

        })
      end
    rescue Exception => error
      return error
    end

    formatted_audit_lever_entries
  end
end
