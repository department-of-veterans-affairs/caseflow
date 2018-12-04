class VACOLS::Staff < VACOLS::Record
  self.table_name = "vacols.staff"
  self.primary_key = "stafkey"
  scope :load_users_by_css_ids, ->(css_ids) { where(sdomainid: css_ids) }

  def self.active_judges
    where("sattyid is not null and sactive = 'A' and svlj = ?", "J")
  end

  def self.active_hearing_coordinators
    where("stitle = 'HRG' and sactive = 'A'")
  end
end
