class RenameClaimantIdToPersonIdInAodGrants < ActiveRecord::Migration[5.1]
  def change
  	rename_column :advance_on_docket_grants, :claimant_id, :person_id
  end
end
