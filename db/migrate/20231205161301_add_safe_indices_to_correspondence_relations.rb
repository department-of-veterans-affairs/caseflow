class AddSafeIndicesToCorrespondenceRelations < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def change
    add_safe_index :correspondence_relations, [:correspondence_id, :related_correspondence_id], unique: true, name: 'index_correspondence_relations_on_correspondences'
    add_safe_index :correspondence_relations, [:related_correspondence_id, :correspondence_id], unique: true, name: 'index_correspondence_relations_on_related_correspondences'
  end
end
