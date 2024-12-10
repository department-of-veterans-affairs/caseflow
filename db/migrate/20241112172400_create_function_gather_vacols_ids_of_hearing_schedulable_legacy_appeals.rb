class CreateFunctionGatherVacolsIdsOfHearingSchedulableLegacyAppeals < ActiveRecord::Migration[6.1]
  def change
    create_function :gather_vacols_ids_of_hearing_schedulable_legacy_appeals
  end
end
