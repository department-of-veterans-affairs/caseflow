# frozen_string_literal: true

class UpdateVeteranAttribsService
  def update_veterans_for_appeals(appeal_ids)
    appeal_ids.map do |appeal_id|
      update_veteran_for_appeal(appeal_id)
    end
  end

  private

  def update_veteran_for_appeal(appeal_id)
    appeal = Appeal.find_appeal_by_uuid_or_find_legacy_appeal_by_vacols_id(appeal_id)
    if appeal.veteran
      appeal.veteran.refresh_attributes
      appeal.veteran.id
    end
  end
end
