# frozen_string_literal: true

class VACOLS::Folder < VACOLS::Record
  # :nocov:
  self.table_name = "vacols.folder"
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
