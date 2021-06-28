# frozen_string_literal: true

class UserRepository
  class << self
    def user_info_from_vacols(css_id)
      staff_record = cached_staff_record(css_id)
      {
        uniq_id: vacols_uniq_id(staff_record),
        roles: vacols_roles(staff_record),
        attorney_id: vacols_attorney_id(staff_record),
        group_id: vacols_group_id(staff_record),
        full_name: vacols_full_name(staff_record)
      }
    end

    def user_info_for_idt(css_id)
      staff_record = cached_staff_record(css_id)
      return {} unless staff_record

      {
        first_name: staff_record.snamef,
        middle_name: staff_record.snamemi,
        last_name: staff_record.snamel,
        attorney_id: vacols_attorney_id(staff_record),
        judge_status: judge_status(staff_record),
        roles: vacols_roles(staff_record),
        css_id: css_id
      }
    end

    def fail_if_no_access_to_task!(css_id, vacols_id)
      unless QueueRepository.tasks_for_user(css_id).map(&:vacols_id).include?(vacols_id)
        msg = "User with css ID #{css_id} cannot modify appeal data with vacols ID: #{vacols_id}"
        fail(Caseflow::Error::UserRepositoryError, message: msg)
      end
      true
    end

    def css_ids_by_vlj_ids(vlj_ids)
      users = VACOLS::Staff.where(sattyid: vlj_ids)

      results = {}
      users.each do |user|
        results[user.sattyid] = {
          css_id: user.sdomainid,
          first_name: user.snamef,
          last_name: user.snamel
        }
      end
      results
    end

    # :nocov:
    def css_id_by_full_name(full_name)
      name = full_name.split(" ")
      first_name = name.first
      last_name = name.last
      staff = VACOLS::Staff.where("snamef LIKE ? and snamel LIKE ?", "%#{first_name}%", "%#{last_name}%")
      if staff.size > 1
        staff = VACOLS::Staff.where(snamef: first_name, snamel: last_name)
      end
      staff.first.try(:sdomainid)
    end
    # :nocov:

    private

    def cached_staff_record(css_id)
      # Cache long enough to improve performance, but not so long that VACOLS drifts out of sync
      Rails.cache.fetch("#{Rails.env}_staff_record_#{css_id}", expires_in: 1.hour) do
        VACOLS::Staff.find_by_sdomainid(css_id)
      end
    end

    # User#pure_judge_in_vacols? relies on "judge" being the first element
    def roles_based_on_staff_fields(staff_record)
      case staff_record.svlj
      when "J"
        ["judge"]
      when "A"
        staff_record.sattyid ? %w[attorney judge] : []
      when nil
        check_other_staff_fields(staff_record)
      else
        []
      end
    end

    def judge_status(staff_record)
      case staff_record.svlj
      when "J"
        "judge"
      when "A"
        "acting judge"
      else
        "none"
      end
    end

    def check_other_staff_fields(staff_record)
      return ["attorney"] if staff_record.sattyid

      roles = []
      roles << "colocated" if staff_record.stitle == "A1" || staff_record.stitle == "A2"
      roles << "dispatch" if staff_record.sdept == "DSP"
      roles
    end

    def vacols_uniq_id(staff_record)
      staff_record.try(:slogid)
    end

    # STAFF.SVLJ = 'J' indicates a user is a Judge, the field may also have an 'A' which indicates an Acting judge.
    # If the STAFF.SVLJ is nil and STAFF.SATTYID is not nil then it is an attorney.
    def vacols_roles(staff_record)
      return roles_based_on_staff_fields(staff_record) if staff_record

      []
    end

    # :nocov:
    def vacols_attorney_id(staff_record)
      staff_record.try(:sattyid)
    end

    def vacols_group_id(staff_record)
      staff_record.try(:stitle) || ""
    end

    def vacols_full_name(staff_record)
      if staff_record
        FullName.new(staff_record.snamef, staff_record.snamemi, staff_record.snamel).formatted(:readable_full)
      end
    end
    # :nocov:
  end
end
