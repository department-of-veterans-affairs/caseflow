class ConvertConferenceIdsToStrings < Caseflow::Migration
  def up
    safety_assured do
      change_column :conference_links, :conference_id, :string
      change_column :virtual_hearings, :conference_id, :string
    end
  end

  def down
    safety_assured do
      execute("ALTER TABLE conference_links ALTER COLUMN conference_id TYPE integer USING(conference_id::integer)")
      execute("ALTER TABLE virtual_hearings ALTER COLUMN conference_id TYPE integer USING(conference_id::integer)")
    end
  end
end
