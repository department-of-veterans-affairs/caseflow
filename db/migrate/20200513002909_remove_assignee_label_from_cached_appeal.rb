class RemoveAssigneeLabelFromCachedAppeal < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :cached_appeal_attributes, :assignee_label, :string, comment: "Queues will now use the actual task assignee rather than the appeal's assigned to location"
    end
  end
end
