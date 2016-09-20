class CreateCertifications < ActiveRecord::Migration
  def change
    create_table :certifications do |t|
      t.string   :vacols_id
      t.boolean  :already_certified
      t.boolean  :vacols_data_missing
      t.datetime :nod_matching_at
      t.datetime :soc_matching_at
      t.datetime :form9_matching_at
      t.boolean  :ssocs_required
      t.datetime :ssocs_matching_at
      t.datetime :form8_started_at
      t.datetime :completed_at
 
      t.timestamps null: false
    end
  end
end
