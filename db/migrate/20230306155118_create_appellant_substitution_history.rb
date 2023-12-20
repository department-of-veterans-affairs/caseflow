class CreateAppellantSubstitutionHistory < ActiveRecord::Migration[5.2]
  def change
    create_table :appellant_substitution_histories do |t|
      t.references :appellant_substitution, index: { name: :index_appellant_sub_histories_on_appellant_substitution_id }, comment: "Appellant substitution id of the last user that updated the CAVC record"
      t.date       :substitution_date, comment: "Timestamp of substitution granted date"
      t.string     :original_appellant_veteran_participant_id, comment: "Original Appeallant Veteran Participant Id"
      t.string     :current_appellant_substitute_participant_id, comment: "Current Appellant Substitute participant Id"
      t.string     :original_appellant_substitute_participant_id, comment: "Original Appellant Substitute participant Id"
      t.string     :current_appellant_veteran_participant_id, comment: "Current Appellant Veteran participant Id"
      t.bigint     :created_by_id, comment: "Current user who created Appellant substitution"
      t.timestamps
    end
  end
end
