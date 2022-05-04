# frozen_string_literal: true

class AssignChangeHearingRequestTypeTasks < ApplicationRecord
  def process_appeals
    # set the cutoff date as the current date plus 11 days.
    cutoff_date = Time.zone.today + 11

    # cycle each appeal in database with a docket type of "hearing"
    Appeal.where(docket_type: "hearing").find_each do |appeal|
      # search the hearings in the appeal to find the open hearing day id
      hearing_day_id = find_open_hearing(appeal.hearings)

      # get the hearing scheduled date using the hearing day id
      hearing_scheduled_date = HearingDay.find(id: hearing_day_id).scheduled_for

      if (hearing_scheduled_date > cutoff_date) || hearing_scheduled_date.nil?

        # get the representatives for the appeal hearing. 

      end
    end
  end

  def find_open_hearing(appeal_hearings)
    # cycle the hearings and throw out the ones that have a disposition
    for hearing in appeal_hearings
      # the disposition is nil, the open hearing has been found
      if hearing.disposition.nil?
        # get the hearing day id and return
        return hearing.hearing_day_id
      end
    end
  end
end
