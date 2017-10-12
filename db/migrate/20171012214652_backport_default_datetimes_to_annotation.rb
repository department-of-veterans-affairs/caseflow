class BackportDefaultDatetimesToAnnotation < ActiveRecord::Migration
  def change
    Annotation.select(:id).find_in_batches.with_index do |records, index|
      Annotation.where(id: records).update_all(created_at: Time.now.utc)
      Annotation.where(id: records, updated_at: nil).update_all(updated_at: Time.now.utc)
    end
  end
end
