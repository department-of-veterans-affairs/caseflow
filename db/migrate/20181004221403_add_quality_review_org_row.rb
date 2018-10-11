class AddQualityReviewOrgRow < ActiveRecord::Migration[5.1]
  def up
    QualityReview.singleton
  end

  def down
    QualityReview.delete_all
  end
end
