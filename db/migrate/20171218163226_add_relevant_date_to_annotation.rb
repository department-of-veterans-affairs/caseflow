class AddRelevantDateToAnnotation < ActiveRecord::Migration
  def change
    add_column :annotations, :relevant_date, :date
  end
end
