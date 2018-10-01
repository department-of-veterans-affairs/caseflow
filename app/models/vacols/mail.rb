class VACOLS::Mail < VACOLS::Record
  self.table_name = "vacols.mail"

  def outstanding?
    return false if mlcompdate
    !%w[02 13].include?(mltype)
  end
end
