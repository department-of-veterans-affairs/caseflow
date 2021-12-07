# frozen_string_literal: true

class VACOLS::Correspondent < VACOLS::Record
  self.table_name = "corres"
  self.primary_key = "stafkey"

  has_many :cases, foreign_key: :bfcorkey
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: corres
#
#  sactive   :string(1)
#  saddrcnty :string(20)
#  saddrcty  :string(20)
#  saddrnum  :string(10)
#  saddrst1  :string(60)
#  saddrst2  :string(60)
#  saddrstt  :string(4)
#  saddrzip  :string(10)
#  sadvage   :string(1)
#  sals      :string(1)
#  sdept     :string(50)
#  sdob      :date
#  sfinhard  :string(1)
#  sfnod     :date
#  sgender   :string(1)
#  shomeless :string(1)
#  sincar    :string(1)
#  slogid    :string(16)       indexed
#  smoh      :string(1)
#  snamef    :string(24)
#  snamel    :string(60)       indexed
#  snamemi   :string(4)
#  snotes    :string(80)
#  sorc1     :integer
#  sorc2     :integer
#  sorc3     :integer
#  sorc4     :integer
#  sorg      :string(50)
#  spgwv     :string(1)
#  spow      :string(1)
#  ssalut    :string(15)
#  ssn       :string(9)        indexed
#  sspare1   :string(20)
#  sspare2   :string(20)
#  sspare3   :string(20)
#  sspare4   :string(10)
#  ssys      :string(16)
#  stadtime  :date
#  staduser  :string(16)
#  stafkey   :string(16)       primary key, indexed
#  stc1      :integer
#  stc2      :integer
#  stc3      :integer
#  stc4      :integer
#  stelfax   :string(20)
#  stelh     :string(20)
#  stelw     :string(20)
#  stelwex   :string(20)
#  stermill  :string(1)
#  stitle    :string(40)
#  stmdtime  :date
#  stmduser  :string(16)
#  susrpw    :string(16)
#  susrsec   :string(5)
#  susrtyp   :string(10)
#  svsi      :string(1)
#
