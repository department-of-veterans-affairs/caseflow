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

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: staff
#
#  sactive   :string(1)
#  saddrcnty :string(6)
#  saddrcty  :string(20)
#  saddrnum  :string(10)
#  saddrst1  :string(30)
#  saddrst2  :string(30)
#  saddrstt  :string(4)
#  saddrzip  :string(10)
#  sattyid   :string(4)
#  sdept     :string(60)
#  sdomainid :string(20)       indexed
#  sfoiasec  :boolean
#  sinvsec   :string(1)
#  slogid    :string(16)       indexed
#  smemgrp   :string(16)
#  snamef    :string(24)
#  snamel    :string(60)       indexed
#  snamemi   :string(4)
#  snotes    :string(80)
#  sorc1     :integer
#  sorc2     :integer
#  sorc3     :integer
#  sorc4     :integer
#  sorg      :string(60)       indexed
#  srptsec   :boolean
#  ssalut    :string(15)
#  sspare1   :string(20)
#  sspare2   :string(20)
#  sspare3   :string(20)
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
#  stitle    :string(60)
#  stmdtime  :date
#  stmduser  :string(16)
#  susrpw    :string(16)
#  susrsec   :string(5)
#  susrtyp   :string(10)
#  svlj      :string(1)
#
