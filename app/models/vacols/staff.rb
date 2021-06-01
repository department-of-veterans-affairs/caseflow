# frozen_string_literal: true

class VACOLS::Staff < VACOLS::Record
  self.table_name = "staff"
  self.primary_key = "stafkey"

  scope :load_users_by_css_ids, ->(css_ids) { where(sdomainid: css_ids) }
  scope :active,                ->          { where(sactive: "A") }
  scope :having_css_id,         ->          { where.not(sdomainid: nil) }
  scope :having_attorney_id,    ->          { where.not(sattyid: nil) }
  scope :pure_judge,            ->          { active.having_attorney_id.where(svlj: "J") }
  scope :acting_judge,          ->          { active.having_attorney_id.where(svlj: "A") }
  scope :pure_attorney,         ->          { active.having_attorney_id.where(svlj: nil) }
  scope :judge,                 ->          { pure_judge.or(acting_judge) }
  scope :attorney,              ->          { pure_attorney.or(acting_judge) }

  def self.find_by_css_id(css_id)
    find_by(sdomainid: css_id)
  end

  def self.css_ids_from_records_with_css_ids(staff_records)
    staff_records.having_css_id.pluck(:sdomainid).map(&:upcase)
  end
end
