class CreateAdvancedOnDocketGrants < ActiveRecord::Migration[5.1]
  def change
    create_table :advance_on_docket_grants do |t|
      t.belongs_to :claimant
      t.belongs_to :user
      t.string :reason
      t.timestamps null: false
    end
  end
end
