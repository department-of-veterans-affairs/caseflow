class CorrespondenceResponseLettersRenameTypeToLetterType < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :correspondence_response_letters, :type }

    add_column :correspondence_response_letters, :letter_type, :string, null: false,
                                                                        comment: "Correspondence response letter type"
  end
end
