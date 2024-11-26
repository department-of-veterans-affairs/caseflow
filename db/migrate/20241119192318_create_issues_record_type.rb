class CreateIssuesRecordType < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      execute(
        <<-SQL
          CREATE TYPE issues_record AS (
            isskey VARCHAR(12),
            issseq SMALLINT,
            issprog VARCHAR(6),
            isscode VARCHAR(6),
            isslev1 VARCHAR(6),
            isslev2 VARCHAR(6),
            isslev3 VARCHAR(6),
            issdc VARCHAR(1),
            issdcls DATE,
            issadtime DATE,
            issaduser VARCHAR(16),
            issmdtime DATE,
            issmduser VARCHAR(16),
            issdesc VARCHAR(100),
            isssel VARCHAR(1),
            issgr VARCHAR(1),
            issdev VARCHAR(2),
            issmst VARCHAR(1),
            isspact VARCHAR(1)
          )
        SQL
      )
    end
  end

  def down
    safety_assured { execute("DROP TYPE issues_record") }
  end
end
