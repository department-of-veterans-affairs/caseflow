class CorrespondenceResponseLettersRenameTypeToLetterType < Caseflow::Migration
  def change
    safety_assured { remove_column :correspondence_response_letters, :type, :string }

    add_column :correspondence_response_letters, :letter_type, :string, null: false,
                                                                        comment: "Correspondence response letter type"
  end
end
