class CreateCorresRecordType < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      execute(
        <<-SQL
          CREATE TYPE corres_record AS (
            stafkey VARCHAR(16),
            susrpw VARCHAR(16),
            susrsec VARCHAR(5),
            susrtyp VARCHAR(10),
            ssalut VARCHAR(15),
            snamef VARCHAR(24),
            snamemi VARCHAR(4),
            snamel VARCHAR(60),
            slogid VARCHAR(16),
            stitle VARCHAR(40),
            sorg VARCHAR(50),
            sdept VARCHAR(50),
            saddrnum VARCHAR(10),
            saddrst1 VARCHAR(60),
            saddrst2 VARCHAR(60),
            saddrcty VARCHAR(20),
            saddrstt VARCHAR(4),
            saddrcnty VARCHAR(20),
            saddrzip VARCHAR(10),
            stelw VARCHAR(20),
            stelwex VARCHAR(20),
            stelfax VARCHAR(20),
            stelh VARCHAR(20),
            staduser VARCHAR(16),
            stadtime DATE,
            stmduser VARCHAR(16),
            stmdtime DATE,
            stc1 INTEGER,
            stc2 INTEGER,
            stc3 INTEGER,
            stc4 INTEGER,
            snotes VARCHAR(80),
            sorc1 INTEGER,
            sorc2 INTEGER,
            sorc3 INTEGER,
            sorc4 INTEGER,
            sactive VARCHAR(1),
            ssys VARCHAR(16),
            sspare1 VARCHAR(20),
            sspare2 VARCHAR(20),
            sspare3 VARCHAR(20),
            sspare4 VARCHAR(10),
            ssn VARCHAR(9),
            sfnod DATE,
            sdob DATE,
            sgender VARCHAR(1),
            shomeless VARCHAR(1),
            stermill VARCHAR(1),
            sfinhard VARCHAR(1),
            sadvage VARCHAR(1),
            smoh VARCHAR(1),
            svsi VARCHAR(1),
            spow VARCHAR(1),
            sals VARCHAR(1),
            spgwv VARCHAR(1),
            sincar VARCHAR(1)
          )
        SQL
      )
    end
  end

  def down
    safety_assured { execute("DROP TYPE corres_record") }
  end
end
