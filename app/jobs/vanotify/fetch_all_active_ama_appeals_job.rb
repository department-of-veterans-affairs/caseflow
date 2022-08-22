# frozen_string_literal: true

# Job to fetch all currently active AMA Appeals
class FetchAllActiveAppeals < CaseflowJob
    queue_with_priority :low_priority

    def create_ama_appeals_list
      Rails.logger.info "Fetch Active AMA Appeals"
    end

    def create_hlr_appeals_list
        Rails.logger.info "Fetch Active High Level Review Appeals"
    end

    def create_supplemental_appeals_list
        Rails.logger.info "Fetch Active Supplemental Claims Appeals"
    end

    def create_legacy_appeals_list
        Rails.logger.info "Fetch Active Legacy Appeals"
    end
end
