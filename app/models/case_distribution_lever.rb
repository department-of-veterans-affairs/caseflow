class CaseDistributionLever < ApplicationRecord

  validates :item, presence: true
  validates :title, presence: true
  validates :data_type, presence: true
  validates :value, presence: true, if: Proc.new { |lever| lever.data_type != 'number' }
  validates :is_active, inclusion: { in: [true, false] }
  validates :is_disabled, inclusion: { in: [true, false] }

  self.table_name = "case_distribution_levers"
  INTEGER_LEVERS = %w(direct_docket_time_goal request_more_cases_minimum alternative_batch_size batch_size_per_attorney days_before_goal_due_for_distribution ama_hearing_case_affinity_days cavc_affinity_days)
  FLOAT_LEVERS = %w(maximum_direct_review_proportion minimum_legacy_proportion nod_adjustment)

  def update_levers(lever_list)
    lever_list.each do |updated_lever|
      updated_lever.save!
    end
  end

  def distribution_value
    if self.data_type == 'radio'
      option = self.options.detect{|opt| opt['item'] == self.value}
      option['value'] if option && option.is_a?(Hash)
    else
      self.value
    end
  end

  class << self
    def find_integer_lever(lever)
      return 0 unless INTEGER_LEVERS.include?(lever)
      CaseDistributionLever.find_by_item(lever).try(:distribution_value).to_i
    end

    def find_float_lever(lever)
      return 0 unless FLOAT_LEVERS.include?(lever)
      CaseDistributionLever.find_by_item(lever).try(:distribution_value).to_f
    end
  end
end
