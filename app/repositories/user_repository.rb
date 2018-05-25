class UserRepository
  class << self
    def staff_records
      @staff_records ||= {}
    end

    def vacols_uniq_id(css_id)
      staff_record_by_css_id(css_id).try(:slogid)
    end

    # STAFF.SVLJ = 'J' indicates a user is a Judge, the field may also have an 'A' which indicates an Acting judge.
    # If the STAFF.SVLJ is nil and STAFF.SATTYID is not nil then it is an attorney.
    def vacols_role(css_id)
      staff_record = staff_record_by_css_id(css_id)
      role_based_on_staff_fields(staff_record) if staff_record
    end

    def can_access_task?(css_id, vacols_id)
      unless QueueRepository.tasks_for_user(css_id).map(&:vacols_id).include?(vacols_id)
        msg = "User with css ID #{css_id} cannot access task with vacols ID: #{vacols_id}"
        fail Caseflow::Error::UserRepositoryError, msg
      end
      true
    end

    # :nocov:
    def vacols_attorney_id(css_id)
      staff_record_by_css_id(css_id).try(:sattyid)
    end

    def vacols_group_id(css_id)
      staff_record_by_css_id(css_id).try(:stitle)
    end

    def vacols_full_name(css_id)
      record = staff_record_by_css_id(css_id)
      if record
        FullName.new(record.snamef, record.snamemi, record.snamel).formatted(:readable_full)
      end
    end

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

    private

    def role_based_on_staff_fields(staff_record)
      case staff_record.svlj
      when "J"
        "Judge"
      when "A"
        staff_record.sattyid ? "Attorney" : "Judge"
      when nil
        "Attorney" if staff_record.sattyid
      end
    end

    def staff_record_by_css_id(css_id)
      staff_records[css_id] ||= VACOLS::Staff.find_by(sdomainid: css_id)
      staff_records[css_id]
    end
    # :nocov:
  end
end
