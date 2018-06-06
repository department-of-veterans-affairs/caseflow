class RenameTypeToTitleInAttorneyCaseReviews < ActiveRecord::Migration[5.1]
  def change
    rename_column :attorney_case_reviews, :type, :document_type
  end
end
