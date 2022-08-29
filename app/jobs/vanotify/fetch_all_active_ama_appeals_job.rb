# frozen_string_literal: true

# Job to fetch all currently active AMA Appeals
class FetchAllActiveAppeals < CaseflowJob
#    queue_with_priority :low_priority

    def find_active_appeals
      #Fetch Active AMA Appeals
      active_ama_appeals = Array.new
      ama_appeals = Appeal.open.where(
        appeal_active: true
      )
      ama_info = Array.new
      active_ama_appeals.each {|i| ama_info << "#{a.id}, #{a.claimaint.participant_id}, AMA Appeal"}
    end
end
