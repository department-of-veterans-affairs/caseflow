# frozen_string_literal: true

class EduRegionalProcessingOffice < Organization
    def can_receive_task?(_task)
      false
    end
  
end
  