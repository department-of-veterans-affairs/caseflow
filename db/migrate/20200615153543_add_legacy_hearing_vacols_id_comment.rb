class AddLegacyHearingVacolsIdComment < ActiveRecord::Migration[5.2]
  def change
    change_column_comment :legacy_hearings, :vacols_id, "Corresponds to VACOLS’ hearsched.hearing_pkseq"
  end
end
