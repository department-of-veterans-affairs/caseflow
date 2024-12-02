class RemoveCorrespondenceIdAndUserIdFromCorrespondenceIntakes < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      remove_reference :correspondence_intakes, :correspondence, foreign_key: true, index: false
      remove_reference :correspondence_intakes, :user, foreign_key: true, index: false
    end
  end
end
