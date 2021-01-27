# frozen_string_literal: true

module Seeds
  class CavcAmaAppeals < Base
    def initialize
      @ama_appeals = []
    end

    def seed!
      create_cavc_ama_appeals
    end

    private

    def create_cavc_ama_appeals
      create_cavc_appeals_at_send_letter
    end

    def create_cavc_appeals_at_send_letter
      9.times do
        create(:cavc_remand,
               judge: JudgeTeam.first.admin,
               attorney: JudgeTeam.first.non_admins.first,
               veteran: Veteran.first)
      end
    end
  end
end
