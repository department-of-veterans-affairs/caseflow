# frozen_string_literal: true

# find all LegacyAppeals with no corresponding VACOLS case.

class LegacyAppealsWithNoVacolsCase < DataIntegrityChecker
  def call
    # we have 1mm+ records to check.
    # VACOLS can support a max of 1000 at a time which is the find_in_batches default.
    LegacyAppeal.find_in_batches.with_index do |legacy_appeals, batch|
      check_legacy_appeals(legacy_appeals, batch)
    end
  end

  private

  def check_legacy_appeals(legacy_appeals, batch)
    Rails.logger.debug("Starting LegacyAppeal/VACOLS check batch #{batch}")

    vacols_ids = legacy_appeals.pluck(:vacols_id)
    vacols_ids_count = vacols_ids.count

    Rails.logger.debug("Found #{vacols_ids_count} vacols_id values")

    # we only care if the counts are different. that tells us to look more closely at this batch.
    vacols_cases_count = VACOLS::Case.where(bfkey: [vacols_ids]).count
    Rails.logger.debug("Found #{vacols_cases_count} VACOLS cases")

    return if vacols_cases_count == vacols_ids_count

    find_legacy_appeals_with_missing_case(vacols_ids)
  end

  def find_legacy_appeals_with_missing_case(vacols_ids)
    # skip any LegacyAppeal with all cancelled tasks since those we know about.
    vacols_ids = legacy_appeals_worth_investigating(vacols_ids)
    vacols_ids_count = vacols_ids.count

    Rails.logger.debug("Found #{vacols_ids_count} VACOLS cases worth investigating")
    return if vacols_ids_count == 0

    vacols_ids_found = VACOLS::Case.select(:bfkey).where(bfkey: [vacols_ids]).pluck(:bfkey)
    missing_from_vacols = vacols_ids - vacols_ids_found
    missing_from_vacols.each do |vacols_id|
      add_to_report "LegacyAppeal.find_by(vacols_id: '#{vacols_id}')"
    end
  end

  # skip any LegacyAppeal with all cancelled tasks since those we know about.
  def legacy_appeals_worth_investigating(vacols_ids)
    [
      legacy_appeals_with_open_tasks(vacols_ids).pluck(:vacols_id),
      legacy_appeals_with_zero_tasks(vacols_ids).pluck(:vacols_id)
    ].flatten.uniq
  end

  def legacy_appeals_with_open_tasks(vacols_ids)
    LegacyAppeal.includes(:tasks).where(tasks: { status: Task.open_statuses }).where(vacols_id: vacols_ids)
  end

  def legacy_appeals_with_zero_tasks(vacols_ids)
    LegacyAppeal.left_outer_joins(:tasks).where(tasks: { id: nil }).where(vacols_id: vacols_ids)
  end
end
