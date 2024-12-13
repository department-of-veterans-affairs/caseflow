class CreateFolderRecordType < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      execute(
        <<-SQL
          CREATE TYPE folder_record AS (
            ticknum VARCHAR(12),
            ticorkey VARCHAR(16),
            tistkey VARCHAR(16),
            tinum VARCHAR(20),
            tifiloc VARCHAR(20),
            tiaddrto VARCHAR(10),
            titrnum VARCHAR(20),
            ticukey VARCHAR(10),
            tidsnt DATE,
            tidrecv DATE,
            tiddue DATE,
            tidcls DATE,
            tiwpptr VARCHAR(250),
            tiwpptrt VARCHAR(2),
            tiaduser VARCHAR(16),
            tiadtime DATE,
            timduser VARCHAR(16),
            timdtime DATE,
            ticlstme DATE,
            tiresp1 VARCHAR(5),
            tikeywrd VARCHAR(250),
            tiactive VARCHAR(1),
            tispare1 VARCHAR(30),
            tispare2 VARCHAR(20),
            tispare3 VARCHAR(30),
            tiread1 VARCHAR(28),
            tiread2 VARCHAR(16),
            timt VARCHAR(10),
            tisubj1 VARCHAR(1),
            tisubj VARCHAR(1),
            tisubj2 VARCHAR(1),
            tisys VARCHAR(16),
            tiagor VARCHAR(1),
            tiasbt VARCHAR(1),
            tigwui VARCHAR(1),
            tihepc VARCHAR(1),
            tiaids VARCHAR(1),
            timgas VARCHAR(1),
            tiptsd VARCHAR(1),
            tiradb VARCHAR(1),
            tiradn VARCHAR(1),
            tisarc VARCHAR(1),
            tisexh VARCHAR(1),
            titoba VARCHAR(1),
            tinosc VARCHAR(1),
            ti38us VARCHAR(1),
            tinnme VARCHAR(1),
            tinwgr VARCHAR(1),
            tipres VARCHAR(1),
            titrtm VARCHAR(1),
            tinoot VARCHAR(1),
            tioctime DATE,
            tiocuser VARCHAR(16),
            tidktime DATE,
            tidkuser VARCHAR(16),
            tipulac DATE,
            ticerullo DATE,
            tiplnod VARCHAR(1),
            tiplwaiver VARCHAR(1),
            tiplexpress VARCHAR(1),
            tisnl VARCHAR(1),
            tivbms VARCHAR(1),
            ticlcw VARCHAR(1)
          )
        SQL
      )
    end
  end

  def down
    safety_assured { execute("DROP TYPE folder_record") }
  end
end
