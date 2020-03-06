# frozen_string_literal: true

class AddIssuesToPostDecisionMotions < ActiveRecord::Migration[5.1]
  def change
    add_column :post_decision_motions, :vacated_decision_issue_ids, :integer, array: true, comment: "When a motion to vacate is partially granted, this includes an array of the appeal's decision issue IDs that were chosen for vacatur in this post-decision motion"
  end
end
