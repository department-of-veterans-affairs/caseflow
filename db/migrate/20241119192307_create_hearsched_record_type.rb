class CreateHearschedRecordType < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      execute(
        <<-SQL
          CREATE TYPE hearsched_record AS (
            hearing_pkseq INTEGER,
            hearing_type VARCHAR(1),
            folder_nr VARCHAR(12),
            hearing_date DATE,
            hearing_disp VARCHAR(1),
            board_member VARCHAR(20),
            notes1 VARCHAR(1000),
            team VARCHAR(2),
            room VARCHAR(4),
            rep_state VARCHAR(2),
            mduser VARCHAR(16),
            mdtime DATE,
            reqdate DATE,
            clsdate DATE,
            recmed VARCHAR(1),
            consent DATE,
            conret DATE,
            contapes VARCHAR(1),
            tranreq VARCHAR(1),
            transent DATE,
            wbtapes SMALLINT,
            wbbackup VARCHAR(1),
            wbsent DATE,
            recprob VARCHAR(1),
            taskno VARCHAR(7),
            adduser VARCHAR(16),
            addtime DATE,
            aod VARCHAR(1),
            holddays SMALLINT,
            vdkey VARCHAR(12),
            repname VARCHAR(25),
            vdbvapoc VARCHAR(40),
            vdropoc VARCHAR(40),
            canceldate DATE,
            addon VARCHAR(1)
          )
        SQL
      )
    end
  end

  def down
    safety_assured { execute("DROP TYPE hearsched_record") }
  end
end
