class AddAssigneeLabelToCachedAppealsAttributeTable < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_appeal_attributes, :assignee_label, :string, comment: "Who is currently most responsible for the appeal"
  end
end
