class AppealSeries < ActiveRecord::Base
  has_many :appeals

  attr_accessor :incomplete

  def self.appeal_series_by_vbms_id(vbms_id)
    appeals = AppealRepository.appeals_by_vbms_id(vbms_id)

    # count number without a series
    # if greater than 0, call assign series

    # create and return unique list of all the series
  end

  private

  def self.generate_appeal_series_from_appeals(appeals)
  end
end
