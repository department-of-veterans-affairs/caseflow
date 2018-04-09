class AddRelevantDateToAnnotation < ActiveRecord::Migration[5.1]
  def change
    add_column :annotations, :relevant_date, :date
  end
end
