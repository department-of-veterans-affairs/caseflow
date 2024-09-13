class CreateRemandsView < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      execute <<-SQL
        CREATE VIEW remands AS
          SELECT *
          FROM supplemental_claims
          WHERE type = 'Remand';
      SQL
    end
  end

  def down
    safety_assured do
      execute <<-SQL
        DROP VIEW remands;
      SQL
    end
  end
end
