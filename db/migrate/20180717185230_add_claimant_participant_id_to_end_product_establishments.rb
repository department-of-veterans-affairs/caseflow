class AddClaimantParticipantIdToEndProductEstablishments < ActiveRecord::Migration[5.1]
  def change
    add_column :end_product_establishments, :claimant_participant_id, :string
  end
end
