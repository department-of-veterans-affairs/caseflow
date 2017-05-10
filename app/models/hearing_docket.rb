class HearingDocket
  include ActiveModel::Model

  attr_accessor :date, :type, :regional_office, :scheduled

  class << self
    def all_for_judge(vlj_id)
      hearings = Appeal.repository.hearings(vlj_id)
      hearings.group_by(&:date)
    end
  end
end
