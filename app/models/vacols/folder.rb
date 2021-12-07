# frozen_string_literal: true

class VACOLS::Folder < VACOLS::Record
  # :nocov:
  self.table_name = "folder"
  self.primary_key = "ticknum"

  has_one :outcoder, foreign_key: :slogid, primary_key: :tiocuser, class_name: "Staff"

  # The attributes that are copied over when the folder is cloned because of a remand
  def remand_clone_attributes
    slice(
      :ticorkey, :tistkey, :titrnum, :tinum, :tiadtime, :tiagor, :tiasbt, :tigwui,
      :tihepc, :tiaids, :timgas, :tiptsd, :tiradb, :tiradn, :tisarc, :tisexh,
      :titoba, :tinosc, :ti38us, :tinnme, :tinwgr, :tipres, :titrtm, :tinoot
    )
  end
  # :nocov:
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: folder
#
#  ti38us      :string(1)
#  tiactive    :string(1)
#  tiaddrto    :string(10)
#  tiadtime    :date
#  tiaduser    :string(16)
#  tiagor      :string(1)
#  tiaids      :string(1)
#  tiasbt      :string(1)
#  ticerullo   :date
#  ticknum     :string(12)       primary key, indexed
#  ticlcw      :string(1)
#  ticlstme    :date
#  ticorkey    :string(16)       indexed
#  ticukey     :string(10)
#  tidcls      :date             indexed
#  tiddue      :date
#  tidktime    :date
#  tidkuser    :string(16)       indexed
#  tidrecv     :date
#  tidsnt      :date
#  tifiloc     :string(20)
#  tigwui      :string(1)
#  tihepc      :string(1)
#  tikeywrd    :string(250)
#  timdtime    :date
#  timduser    :string(16)
#  timgas      :string(1)
#  timt        :string(10)
#  tinnme      :string(1)
#  tinoot      :string(1)
#  tinosc      :string(1)
#  tinum       :string(20)       indexed
#  tinwgr      :string(1)
#  tioctime    :date
#  tiocuser    :string(16)       indexed
#  tiplexpress :string(1)
#  tiplnod     :string(1)
#  tiplwaiver  :string(1)
#  tipres      :string(1)
#  tiptsd      :string(1)
#  tipulac     :date
#  tiradb      :string(1)
#  tiradn      :string(1)
#  tiread1     :string(28)
#  tiread2     :string(16)
#  tiresp1     :string(5)
#  tisarc      :string(1)
#  tisexh      :string(1)
#  tisnl       :string(1)
#  tispare1    :string(30)       indexed
#  tispare2    :string(20)
#  tispare3    :string(30)
#  tistkey     :string(16)
#  tisubj      :string(1)
#  tisubj1     :string(1)
#  tisubj2     :string(1)
#  tisys       :string(16)
#  titoba      :string(1)
#  titrnum     :string(20)       indexed
#  titrtm      :string(1)
#  tivbms      :string(1)
#  tiwpptr     :string(250)
#  tiwpptrt    :string(2)
#
