class AttorneyQueue < BaseQueue
  def self.tasks(user_id)
    css_id = User.find(user_id).css_id
    case_assignments = Appeal.repository.load_user_case_assignments_from_vacols(css_id)

    case_assignments.map do |assignment|
      DraftDecision.from_vacols(assignment, user_id)
    end
  end

  # We don't redefine the repository as a fake
  # on BaseQueue until after autoloading happens,
  # so if we rely on the autoloaded method we'll never
  # get the fake. Awwwkward.
  def self.repository
    BaseQueue.repository
  end
end
