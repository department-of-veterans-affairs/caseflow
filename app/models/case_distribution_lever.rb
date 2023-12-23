class CaseDistributionLever < ApplicationRecord

  validates :item, presence: true
  validates :title, presence: true
  validates :data_type, presence: true
  validates :value, presence: true, if: Proc.new { |lever| lever.data_type != 'number' }
  validates :is_active, inclusion: { in: [true, false] }
  validates :is_disabled, inclusion: { in: [true, false] }

  self.table_name = "case_distribution_levers"

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

  def find_integer_lever(lever)
  end

  def find_float_lever(lever)
  end
end
