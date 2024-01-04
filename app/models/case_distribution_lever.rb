class CaseDistributionLever < ApplicationRecord

  validates :item, presence: true
  validates :title, presence: true
  validates :data_type, presence: true
  validates :value, presence: true, if: Proc.new { |lever| lever.data_type != Constants.ACD_LEVERS.number }
  validates :is_active, inclusion: { in: [true, false] }
  validates :is_disabled, inclusion: { in: [true, false] }

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
end
