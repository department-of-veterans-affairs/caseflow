# frozen_string_literal: true

class VACOLS::CAVCCaseDecision < VACOLS::Record
  self.table_name = "cova"
  self.primary_key = "cvfolder"
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: cova
#
#  cv30date    :date
#  cv30dind    :string(1)
#  cvbm1       :string(4)
#  cvbm2       :string(4)
#  cvbm3       :string(4)
#  cvbm3plus   :string(1)
#  cvcomments  :string(300)
#  cvddec      :date
#  cvdisp      :string(1)
#  cvdocket    :string(7)
#  cvfedcir    :string(1)
#  cvfolder    :string(12)       primary key, indexed
#  cvissseq    :integer
#  cvjmr       :string(1)
#  cvjmrdate   :date
#  cvjoint     :string(1)
#  cvjudge     :string(30)
#  cvjudgement :date
#  cvlitmat    :string(1)
#  cvloc       :string(1)
#  cvmandate   :date
#  cvogcatty   :string(30)
#  cvogcdep    :string(30)
#  cvrep       :string(1)
#  cvrr        :string(132)
#  cvrrtext    :string(160)
#  cvstatus    :string(1)
#
