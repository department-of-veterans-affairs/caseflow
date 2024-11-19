class CreateAssignRecordType < ActiveRecord::Migration[6.1]
def up
    safety_assured do
      execute(
        <<-SQL
          CREATE TYPE assign_record AS (
              tasknum VARCHAR(12),
              tsktknm VARCHAR(12),
              tskstfas VARCHAR(16),
              tskactcd VARCHAR(10),
              tskclass VARCHAR(10),
              tskrqact VARCHAR(280),
              tskrspn VARCHAR(200),
              tskdassn DATE,
              tskdtc INTEGER,
              tskddue DATE,
              tskdcls DATE,
              tskstown VARCHAR(16),
              tskstat VARCHAR(1),
              tskownts VARCHAR(12),
              tskclstm DATE,
              tskadusr VARCHAR(16),
              tskadtm DATE,
              tskmdusr VARCHAR(16),
              tskmdtm DATE,
              tsactive VARCHAR(1),
              tsspare1 VARCHAR(30),
              tsspare2 VARCHAR(30),
              tsspare3 VARCHAR(30),
              tsread1 VARCHAR(28),
              tsread VARCHAR(16),
              tskorder VARCHAR(15),
              tssys VARCHAR(16)
          )
        SQL
      )
    end
  end

  def down
    safety_assured { execute("DROP TYPE assign_record") }
  end
end
