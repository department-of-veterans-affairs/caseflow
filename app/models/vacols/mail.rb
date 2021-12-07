# frozen_string_literal: true

class VACOLS::Mail < VACOLS::Record
  include AddressMapper

  self.table_name = "mail"

  belongs_to :correspondent, foreign_key: :mlcorkey, primary_key: :stafkey

  def outstanding?
    return false if mlcompdate

    !%w[02 13].include?(mltype)
  end

  def congressional_address
    # 02 is the congressional interest mail type. According to Paul Saindon
    # (and verified in prod), mail type 13 with source G and X
    # is also congressional mail.
    if (mltype == "02" || (mltype == "13" && (mlsource == "G" || mlsource == "X"))) && correspondent
      {
        full_name: [
          correspondent.stitle,
          correspondent.snamef,
          correspondent.snamel,
          correspondent.ssalut
        ].select(&:present?).join(" "),
        **get_address_from_corres_entry(correspondent)
      }
    end
  end

  TYPES = {
    "01" => "Change of Address",
    "02" => "Congressional Interest",
    "03" => "Controlled Correspondence",
    "04" => "CUE Related",
    "05" => "Evidence or Argument",
    "06" => "FOIA Request",
    "07" => "Hearing Related",
    "08" => "Motion to Advance on Docket",
    "09" => "Motion for Reconsideration",
    "10" => "Power of Attorney Related",
    "11" => "Professional Service Mail",
    "12" => "Returned or Undeliverable Mail",
    "13" => "Status Inquiry",
    "14" => "Death Certificate",
    "15" => "Appellate Group Mail",
    "16" => "Extension Request",
    "17" => "Privacy Act Request",
    "18" => "Other Motion",
    "19" => "Privacy Complaints",
    "20" => "Intra/Inter Agency Request",
    "21" => "Ebert Temporary Transfer",
    "22" => "How Do I Appeal Pamphlet",
    "23" => "ECA Revocation",
    "24" => "FOIA Request & Other Actions",
    "25" => "Motion to Vacate",
    "26" => "Attorney Inquiry",
    "27" => "Withdrawal of Appeal"
  }.freeze
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: mail
#
#  mlaccess   :string(1)
#  mlactdate  :date
#  mlaction   :string(2)
#  mladdr1    :string(40)
#  mladdr2    :string(40)
#  mladdtime  :date
#  mladduser  :string(16)
#  mlamend    :string(1)
#  mlassignee :string(16)
#  mlauth     :string(1)
#  mlcity     :string(20)
#  mlcompdate :date             indexed
#  mlcontrol  :string(1)
#  mlcorkey   :string(16)
#  mlcorrdate :date
#  mldue2nd   :date
#  mlduedate  :date
#  mledms     :string(10)
#  mlfee      :decimal(8, 2)
#  mlfoiadate :date
#  mlfolder   :string(12)       indexed
#  mllit      :string(1)
#  mlmodtime  :date
#  mlmoduser  :string(16)
#  mlnotes    :string(300)
#  mlpages    :integer
#  mlrecvdate :date
#  mlreqfac   :string(25)
#  mlreqfirst :string(15)
#  mlreqlast  :string(25)
#  mlreqmi    :string(1)
#  mlreqrel   :string(1)
#  mlseq      :integer
#  mlsource   :string(1)
#  mlst       :string(4)
#  mltrack    :string(1)
#  mltype     :string(2)
#  mlzip      :string(10)
#
