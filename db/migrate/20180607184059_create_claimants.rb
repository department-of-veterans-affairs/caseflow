class CreateClaimants < ActiveRecord::Migration[5.1]
  def change
    create_table :claimants do |t|
      t.belongs_to :review_claimant, polymorphic: true, null: false, index: {name: "index_claimants_on_review_request"}
      t.string     :participant_id, null: false
      t.string     :relationship_type
      t.string     :payee_cd
    end
  end
end
