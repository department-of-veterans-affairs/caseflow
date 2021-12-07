# frozen_string_literal: true

class VACOLS::Diary < VACOLS::Record
  self.table_name = "assign"
  self.primary_key = "tsktknm"
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: assign
#
#  tasknum  :string(12)       indexed
#  tsactive :string(1)
#  tskactcd :string(10)       indexed
#  tskadtm  :date
#  tskadusr :string(16)
#  tskclass :string(10)
#  tskclstm :date
#  tskdassn :date
#  tskdcls  :date             indexed
#  tskddue  :date
#  tskdtc   :integer
#  tskmdtm  :date
#  tskmdusr :string(16)
#  tskorder :string(15)
#  tskownts :string(12)
#  tskrqact :string(280)
#  tskrspn  :string(200)
#  tskstat  :string(1)
#  tskstfas :string(16)       indexed
#  tskstown :string(16)       indexed
#  tsktknm  :string(12)       primary key, indexed
#  tsread   :string(16)
#  tsread1  :string(28)
#  tsspare1 :string(30)
#  tsspare2 :string(30)
#  tsspare3 :string(30)
#  tssys    :string(16)
#
