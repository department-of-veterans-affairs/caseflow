class VACOLS::Mail < VACOLS::Record
  self.table_name = "vacols.mail"

  def is_outstanding?
    return false if mlcompdate
    !%w[02 13].include?(mltype)
  end
end
