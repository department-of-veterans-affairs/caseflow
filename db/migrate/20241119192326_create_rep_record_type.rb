class CreateRepRecordType < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      execute(
        <<-SQL
          CREATE TYPE rep_record AS (
            repkey VARCHAR(12),
            repaddtime DATE,
            reptype VARCHAR(1),
            repso VARCHAR(1),
            replast VARCHAR(40),
            repfirst VARCHAR(24),
            repmi VARCHAR(4),
            repsuf VARCHAR(4),
            repaddr1 VARCHAR(50),
            repaddr2 VARCHAR(100),
            repcity VARCHAR(20),
            repst VARCHAR(4),
            repzip VARCHAR(10),
            repphone VARCHAR(20),
            repnotes VARCHAR(50),
            repmoduser VARCHAR(16),
            repmodtime DATE,
            repdirpay VARCHAR(1),
            repdfee DATE,
            repfeerecv DATE,
            replastdoc DATE,
            repfeedisp DATE,
            repcorkey VARCHAR(16),
            repacknw DATE
          )
        SQL
      )
    end
  end

  def down
    safety_assured { execute("DROP TYPE rep_record") }
  end
end
