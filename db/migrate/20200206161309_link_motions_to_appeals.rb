class LinkMotionsToAppeals < ActiveRecord::Migration[5.1]
  def up
    add_reference :post_decision_motions, :appeal, foreign_key: true, index: false
  end

  def down
    safety_assured do
      remove_reference :post_decision_motions, :appeal, foreign_key: true
    end
  end
end
