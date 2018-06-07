class CreateClaimants < ActiveRecord::Migration[5.1]
  def change
    create_table :claimants do |t|
      t.belongs_to :review_request, polymorphic: true, null: false, index: {name: "index_claimants_on_review_request"}
      t.string     :participant_id, null: false
    end
  end
end
