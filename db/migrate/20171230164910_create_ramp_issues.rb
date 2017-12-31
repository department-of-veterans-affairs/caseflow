class CreateRampIssues < ActiveRecord::Migration
  safety_assured

  def change
    create_table :ramp_issues do |t|
      t.belongs_to :review, polymorphic: true, null: false
      t.string     :contention_reference_id, null: false
      t.string     :description, null: false
    end

    add_index(:ramp_issues, [:review_type, :review_id])
  end
end
