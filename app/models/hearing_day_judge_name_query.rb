# frozen_string_literal: true

##
# Gets the first name and last name from VACOLS for the respective Hearing Day.
#
##

class HearingDayJudgeNameQuery
  attr_reader :hearing_days

  def initialize(hearing_days)
    @hearing_days = hearing_days
  end

  def call
    judges_names = {}

    # Make sure that @hearing_days is a collection that we can iterate over.
    return judges_names unless @hearing_days.try(:to_a).is_a? Array

    return judges_names if @hearing_days.empty?

    if @hearing_days.is_a? Array
      ids = @hearing_days.collect(&:id)
      @hearing_days = HearingDay.where(id: ids)
    end

    if hearing_days.length == 1
      vacols_user = hearing_days.first.vacols_user

      judges_names[hearing_days.first.id] = {
        first_name: vacols_user.try(:snamef),
        last_name: vacols_user.try(:snamef)
      }
    else
      hearing_days.includes(:vacols_user).pluck(:id, :snamef, :snamel).each do |day|
        judges_names[day[0]] = { first_name: day[1], last_name: day[2] }
      end
    end

    judges_names
  end
end
