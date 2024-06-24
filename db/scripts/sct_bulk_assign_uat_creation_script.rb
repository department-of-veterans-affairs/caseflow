CREATE_AOD_CASES = true

# Create non-caregiver request issues
def create_vha_request_issue
  RequestIssue.create!(benefit_type: 'vha', is_predocket_needed: false, nonrating_issue_category: Constants::ISSUE_CATEGORIES["vha"].sample, nonrating_issue_description: "Test Data")
end

# Create intake (with intake user)
def create_intake_for_decision_review(decision_review)
  intake_user = Organization.find_by(type: "BvaIntake").users.first
  Intake.create!(completed_at: Time.zone.now, completion_status: "success", started_at: Time.zone.now, detail_id: decision_review.id, detail_type: decision_review.class.name, type: "#{decision_review.class.name}Intake", user_id: intake_user.id, veteran_file_number: decision_review.veteran_file_number, veteran_id: decision_review.veteran.id)
end

# Create new SpecialtyCaseTeamAssignTask and assign to the SpecialtyCaseTeamOrg
def create_specialty_case_team_assign_task(appeal)
  create_aod_cases(appeal) if CREATE_AOD_CASES
  organization = SpecialtyCaseTeam.singleton
  parent_task = appeal.tasks.find_by(type: "RootTask")
  sct = SpecialtyCaseTeamAssignTask.create!(appeal_id: appeal.id, appeal_type: appeal.class.name, assigned_at: Time.zone.now, assigned_to_id: organization.id, assigned_to_type: "Organization", parent_id: parent_task.id, status: 'assigned')
end

def create_aod_cases(appeal)
  claimant = Claimant.create!(participant_id: appeal.veteran.participant_id, decision_review: appeal)
  claimant.person.update!(date_of_birth: 76.years.ago)
  claimant.reload
  appeal.claimants = [claimant]
  appeal.conditionally_set_aod_based_on_age
  appeal.reload
end

def create_appeal(veteran)
  return unless veteran

  # Create appeal
  appeal = Appeal.create!(docket_type: Constants.AMA_DOCKETS.direct_review, established_at: Time.zone.now, filed_by_va_gov: false, receipt_date: Date.today, veteran_file_number: veteran.file_number)

  # Create request issues array and populate it with unique request issues
  request_issues = []
  rand(1..3).times do
    issue = create_vha_request_issue
    request_issues << issue unless request_issues.map(&:nonrating_issue_category).include?(issue.nonrating_issue_category)
  end

  # Add the request issues to the appeal
  appeal.request_issues << request_issues

  create_intake_for_decision_review(appeal)

  # Create tasks on intake success
  appeal.create_tasks_on_intake_success!
  appeal.reload

  # Complete the existing distribution task
  distro_task = appeal.tasks.find_by(type: "DistributionTask")
  distro_task.completed!


  # Create the sct assign task
  create_specialty_case_team_assign_task(appeal)

  appeal
end

# user = User.find_by_css_id('CF_KIRK_283')
user = User.find_by_css_id('ACBAUERVVHAH')

RequestStore[:current_user] = user

number_of_appeals_to_generate = 1

veterans = Veteran.all.sample(number_of_appeals_to_generate)

# Create appeals in the specialty case team bulk assign queue
number_of_appeals_to_generate.times do
  appeal = create_appeal(veterans.pop)
end
