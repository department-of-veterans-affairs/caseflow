# frozen_string_literal: true

class UpdateVeteranAttribsService
  def update_veterans_for_appeals(appeal_ids)
    ama_ids, legacy_ids = appeal_ids.partition { |id| UUID_REGEX.match?(id) }

    @appeals = []
    @appeals << Appeal.includes(:veterans).where(id: ama_ids)
    @appeals << LegacyAppeal.includes(:veterans).where(id: legacy_ids)

    @appeals.each { |appeal| update_veteran_for_appeal(appeal) }
  end

  private

  def update_veteran_for_appeal(appeal)
    if appeal.veteran
      appeal.veteran.refresh_attributes
      appeal.veteran.id
    end
  end
end
