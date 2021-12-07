# frozen_string_literal: true

class VACOLS::Vftypes < VACOLS::Record
  self.table_name = "vftypes"
  self.primary_key = "ftkey"
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: vftypes
#
#  ftactive :string(1)
#  ftadtim  :date
#  ftadusr  :string(16)
#  ftdesc   :string(100)
#  ftkey    :string(10)       primary key, indexed
#  ftmdtim  :date
#  ftmdusr  :string(16)
#  ftspare1 :string(20)
#  ftspare2 :string(20)
#  ftspare3 :string(20)
#  ftsys    :string(100)
#  fttype   :string(16)
#
