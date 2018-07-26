class VACOLS::Staff < VACOLS::Record
  self.table_name = "vacols.staff"
  self.primary_key = "stafkey"

  def self.load_users_by_css_ids(css_ids)
    where(sdomainid: css_ids)
  end
end
