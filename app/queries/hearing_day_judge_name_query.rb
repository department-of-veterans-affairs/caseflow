# frozen_string_literal: true

##
# Gets the first name and last name from VACOLS for the respective Hearing Days.
#
##
class HearingDayJudgeNameQuery
  attr_reader :hearing_days

  def initialize(hearing_days)
    @hearing_days = hearing_days
  end

  def call
    return {} if hearing_days.blank?

    # return a lookup like { 12 => { :first_name => "Leonidas", :last_name => "Olson" } }
    hearing_days.includes(:vacols_user).pluck(:id, :snamef, :snamel).reduce({}) do |lookup, values|
      lookup[values[0]] = { first_name: values[1], last_name: values[2] }
      lookup
    end
  end
end
