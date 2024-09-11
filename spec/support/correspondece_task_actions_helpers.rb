# frozen_string_literal: true

module CorrespondenceTaskActionsHelpers
  TASKS = [
    { class: OtherMotionCorrespondenceTask, name: "Other motion",
      assigned_to_type: "User", assigned_to: :user_team,
      access_type: :user_access, team_name: "Inbound Ops Team" },
    { class: FoiaRequestCorrespondenceTask, name: "FOIA request",
      assigned_to_type: "PrivacyTeam", assigned_to: :privacy_team,
      access_type: :privacy_user_access, team_name: "Privacy Team" },
    { class: CavcCorrespondenceCorrespondenceTask, name: "CAVC Correspondence",
      assigned_to_type: "CavcLitigationSupport", assigned_to: :cavc_team,
      access_type: :cavc_user_access, team_name: "CAVC Litigation Support" },
    { class: CongressionalInterestCorrespondenceTask, name: "Congressional interest",
      assigned_to_type: "LitigationSupport", assigned_to: :liti_team,
      access_type: :litigation_user_access, team_name: "Litigation Support" },
    { class: PrivacyActRequestCorrespondenceTask, name: "Privacy act request",
      assigned_to_type: "PrivacyTeam", assigned_to: :privacy_team,
      access_type: :privacy_user_access, team_name: "Privacy Team" },
    { class: PrivacyComplaintCorrespondenceTask, name: "Privacy complaint",
      assigned_to_type: "PrivacyTeam", assigned_to: :privacy_team,
      access_type: :privacy_user_access, team_name: "Privacy Team" },
    { class: DeathCertificateCorrespondenceTask, name: "Death certificate",
      assigned_to_type: "Colocated", assigned_to: :colocated_team,
      access_type: :colocated_user_access, team_name: "VLJ Support Staff" },
    { class: PowerOfAttorneyRelatedCorrespondenceTask, name: "Power of attorney-related",
      assigned_to_type: "HearingAdmin", assigned_to: :hearings_team,
      access_type: :hearnings_user_access, team_name: "Hearing Admin" },
    { class: StatusInquiryCorrespondenceTask, name: "Status inquiry",
      assigned_to_type: "LitigationSupport", assigned_to: :liti_team,
      access_type: :litigation_user_access, team_name: "Litigation Support" }
  ].freeze

  def correspondence_spec_privacy_user_access
    PrivacyTeam.singleton.add_user(privacy_user)
    User.authenticate!(user: privacy_user)
  end

  def correspondence_spec_cavc_user_access
    CavcLitigationSupport.singleton.add_user(cavc_user)
    User.authenticate!(user: cavc_user)
  end

  def correspondence_spec_litigation_user_access
    LitigationSupport.singleton.add_user(liti_user)
    User.authenticate!(user: liti_user)
  end

  def correspondence_spec_colocated_user_access
    Colocated.singleton.add_user(colocated_user)
    User.authenticate!(user: colocated_user)
  end

  def correspondence_spec_hearnings_user_access
    HearingAdmin.singleton.add_user(hearings_user)
    User.authenticate!(user: hearings_user)
  end

  def setup_correspondence_task(options = {})
    correspondence = options[:correspondence]
    task_class = options[:task_class]
    assigned_to_type = options[:assigned_to_type]
    assigned_to = options[:assigned_to]
    instructions = options[:instructions]

    task = task_class.create!(
      parent: correspondence.tasks[0],
      appeal: correspondence,
      appeal_type: "Correspondence",
      status: "assigned",
      assigned_to_type: assigned_to_type,
      assigned_to: assigned_to,
      instructions: [instructions],
      assigned_at: Time.current
    )
    Organization.assignable(task)
    @organizations = task.reassign_organizations.map { |org| { label: org.name, value: org.id } }
  end

  def check_task_action(options = {})
    correspondence = options[:correspondence]
    task_name = options[:task_name]
    action = options[:action]
    form_text = options[:form_text]
    button_id = options[:button_id]
    expected_message = options[:expected_message]

    visit "/queue/correspondence/#{correspondence.uuid}"
    click_dropdown(prompt: "Select an action", text: action)
    find(".cf-form-textarea", match: :first).fill_in with: form_text
    click_button button_id
    expect(page).to have_content("#{task_name} #{expected_message}")
  end
end
