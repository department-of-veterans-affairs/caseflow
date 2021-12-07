# frozen_string_literal: true

class VACOLS::Actcode < VACOLS::Record
  self.table_name = "actcode"
  self.primary_key = "actckey"
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: actcode
#
#  acactive  :string(1)
#  acspare1  :string(20)
#  acspare2  :string(20)
#  acspare3  :string(20)
#  actadtim  :date
#  actadusr  :string(16)
#  actcdesc  :string(50)
#  actcdesc2 :string(280)
#  actcdtc   :string(3)
#  actckey   :string(10)       primary key, indexed
#  actcsec   :string(5)
#  actcukey  :string(10)
#  actmdtim  :date
#  actmdusr  :string(16)
#  actsys    :string(16)
#
