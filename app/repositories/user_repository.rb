class UserRepository
  def self.vacols_uniq_id(css_id)
    staff = VACOLS::Staff.find_by(sdomainid: css_id)
    fail Caseflow::Error::UserRepositoryError, "Cannot find user with #{css_id} in VACOLS" unless staff
    staff.slogid
  end

  def self.can_access_task?(css_id, vacols_id)
    unless QueueRepository.tasks_for_user(css_id).map(&:vacols_id).include?(vacols_id)
      msg = "User with css ID #{css_id} cannot access task with vacols ID: #{vacols_id}"
      fail Caseflow::Error::UserRepositoryError, msg
    end
  end
end
