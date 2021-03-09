# frozen_string_literal: true

class UpdateVeteranAttribsService
  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

  class << self
    def update_veterans_for_appeals(appeal_ids)
      ama_ids, legacy_ids = appeal_ids.partition { |id| UUID_REGEX.match?(id) }
      appeals = Appeal.where(uuid: ama_ids) + LegacyAppeal.where(id: legacy_ids)
      appeals.each do |appeal|
        update_veteran_for_appeal(appeal)
      end
    end

    def update_veteran_for_appeal(appeal)
      if appeal.veteran
        appeal.veteran.refresh_attributes
        appeal.veteran.id
      end
    end
  end
end
