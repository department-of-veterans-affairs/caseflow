# frozen_string_literal: true

class AddIssuesToPostDecisionMotions < ActiveRecord::Migration[5.1]
  def change
    add_column :post_decision_motions, :vacated_issue_ids, :integer, array: true, comment: "An array of the request issue IDs that were chosen for partial vactur in this post-decision motion."
  end
end
