# frozen_string_literal: true

# Create Users/Organizations used by other seed classes. Some users which exist that are not created in this file are
# created using the seed file populate_caseflow_from_vacols.rb, which mimics Caseflow's creation of some users from
# the VACOLS DB if they do not yet exist in the Caseflow DB.

module Seeds
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/ClassLength
  class Users < Base
    DEVELOPMENT_JUDGE_TEAMS = {
      "BVAAABSHIRE" => { attorneys: %w[BVAEERDMAN BVARDUBUQUE BVALSHIELDS] },
      "BVAGSPORER" => { attorneys: %w[BVAOTRANTOW BVAGBOTSFORD BVAJWEHNER1] },
      "BVAEBECKER" => { attorneys: %w[BVAKBLOCK BVACMERTZ BVAHLUETTGEN] },
      "BVARERDMAN" => { attorneys: %w[BVASRITCHIE BVAJSCHIMMEL BVAKROHAN1] },
      "BVAOSCHOWALT" => { attorneys: %w[BVASCASPER1 BVAOWEHNER BVASFUNK1] },
      "BVAAWAKEFIELD" => { attorneys: %w[BVAABELANGER] },
      # below teams were added for automatic case distribution testing
      "BVAABODE" => { attorneys: %w[BVAABARTELL BVAABERGE BVAABERNIER] },
      "BVABDANIEL" => { attorneys: %w[BVABBLOCK BVABCASPER BVABCHAMPLIN] },
      "BVACGISLASON1" => { attorneys: %w[BVACABERNATH BVACABSHIRE BVACBALISTRE] },
      "BVADCREMIN" => { attorneys: %w[BVADABBOTT BVADABERNATH BVADBEAHAN] },
      "BVAEEMARD" => { attorneys: %w[BVAEBLANDA BVAEBUCKRIDG BVAECUMMERAT] }
    }.freeze

    DEVELOPMENT_DVC_TEAMS = {
      "BVATCOLLIER" => %w[BVAAABSHIRE BVAGSPORER BVAEBECKER]
    }.freeze

    PROGRAM_OFFICES = [
      "Community Care - Payment Operations Management",
      "Community Care - Veteran and Family Members Program",
      "Member Services - Health Eligibility Center",
      "Member Services - Beneficiary Travel",
      "Prosthetics"
    ].freeze

    RPOS = ["Buffalo RPO", "Central Office RPO", "Muskogee RPO"].freeze

    def seed!
      create_users
      create_singleton_organizations
    end

    private

    def create_users
      create(:user, css_id: "CASEFLOW1", station_id: 317, full_name: "System User")
      create(:user, css_id: "BVASCASPER1", full_name: "Steve Attorney_Cases_AVLJ Casper")
      create(:user, css_id: "BVASRITCHIE", full_name: "Sharree AttorneyNoCases Ritchie")
      create(:user, css_id: "BVAAABSHIRE", full_name: "Aaron Judge_HearingsAndCases Abshire")
      create(:user, css_id: "BVARERDMAN", full_name: "Rachael JudgeHasAttorneys_Cases_AVLJ Erdman")
      create(:user, css_id: "BVAEBECKER", full_name: "Elizabeth Judge_CaseToAssign Becker")
      create(:user, css_id: "BVAKKEELING", full_name: "Keith Judge_CaseToAssign_NoTeam Keeling")
      create(:user, css_id: "BVAAWAKEFIELD", full_name: "Apurva Judge_CaseAtDispatch Wakefield")
      create(:user, css_id: "BVAABELANGER", full_name: "Andy Attorney_CaseAtDispatch Belanger")
      create(:user, css_id: "BVATWARNER", full_name: "Theresa BuildHearingSchedule Warner")
      create(:user, css_id: "BVAGWHITE", full_name: "George BVADispatchUser_Cases White")
      create(:user, css_id: "BVAGGREY", full_name: "Gina BVADispatchUser_NoCases Grey")
      create(:user, css_id: "BVATCOLLIER", full_name: "Tonja DVCTeam Collier")

      create_bva_dispatch_admin
      create_case_review_admin
      create_special_case_movement_users
      create_bva_intake_users
      create_qa_admin_for_cda_control_group
      create_team_admin

      # Any users created above Functions.grant! are intended to have "System Admin" access
      Functions.grant!("System Admin", users: User.all.pluck(:css_id))

      create_intake_users
      create_vha_admins
      create_colocated_users
      create_transcription_team
      create_vso_users_and_tasks
      create_field_vso_and_users
      create_pva_vso_and_users
      create_org_queue_users
      create_qr_user
      create_aod_user_and_tasks
      create_privacy_user
      create_lit_support_user
      create_oai_team_user
      create_occ_team_user
      create_cavc_lit_support_user
      create_pulac_cerullo_user
      create_mail_team_user
      create_clerk_of_the_board_users
      create_case_search_only_user
      create_split_appeals_test_users
      create_judge_teams
      create_dvc_teams
      create_hearings_user
      create_build_and_edit_hearings_users
      create_non_admin_hearing_coordinator_user
      add_mail_intake_to_all_bva_intake_users
      create_and_add_cda_control_group_users
      add_users_to_bva_dispatch
      create_qa_test_users

      # Below originated in the VeteransHealthAdministration seed file
      setup_camo_org
      setup_caregiver_org
      setup_program_offices
      setup_specialty_case_team
      create_visn_org_teams

      # Below originated in Education seed file
      setup_emo_org
      setup_rpo_orgs
    end

    def create_bva_dispatch_admin
      dispatch_admin = create(:user, css_id: "BVAGBLACK", full_name: "Geoffrey BVADispatchAdmin_NoCases Black")
      OrganizationsUser.make_user_admin(dispatch_admin, BvaDispatch.singleton)
    end

    def create_case_review_admin
      case_review_admin = create(:user, css_id: "BVAKBLUE", full_name: "Kim CaseReviewAdmin Blue")
      OrganizationsUser.make_user_admin(case_review_admin, CaseReview.singleton)
    end

    def create_special_case_movement_users
      special_case_movement_user = create(:user, :with_vacols_record,
                                          css_id: "BVARDUNKLE", full_name: "Rosalie SpecialCaseMovement Dunkle")
      SpecialCaseMovementTeam.singleton.add_user(special_case_movement_user)

      special_case_movement_admin = create(:user, :with_vacols_record,
                                           css_id: "BVAGBEEKMAN", full_name: "Bryan SpecialCaseMovementAdmin Beekman")
      OrganizationsUser.make_user_admin(special_case_movement_admin, SpecialCaseMovementTeam.singleton)
    end

    def create_bva_intake_users
      bva_intake_admin = create(:user, css_id: "BVADWISE", full_name: "Deborah BvaIntakeAdmin Wise")
      OrganizationsUser.make_user_admin(bva_intake_admin, BvaIntake.singleton)

      bva_intake_user = create(:user, css_id: "BVAISHAW", full_name: "Ignacio BvaIntakeUser Shaw")
      BvaIntake.singleton.add_user(bva_intake_user)
    end

    # This user is intended to be used by QA's in the ACD ART
    def create_qa_admin_for_cda_control_group
      qa_admin = create(
        :user,
        :judge,
        :with_vacols_judge_record,
        css_id: "QAACDPlus",
        full_name: "QA_Admin ACD_CF TM_Mgmt_Intake",
        roles: ["Mail Intake", "Admin Intake", "Hearing Prep"]
      )

      OrganizationsUser.make_user_admin(qa_admin, CDAControlGroup.singleton)
      OrganizationsUser.make_user_admin(qa_admin, BvaIntake.singleton)
      OrganizationsUser.make_user_admin(qa_admin, Bva.singleton)

      # Add attorney so that the judge can be targeted by ama_affinity_cases.rb seed script
      JudgeTeam.for_judge(qa_admin).add_user(User.find_by_css_id("BVASCASPER1"))
    end

    def create_team_admin
      team_admin = create(:user, css_id: "TEAM_ADMIN", full_name: "Jim TeamAdminSystemAdmin Jones")
      Bva.singleton.add_user(team_admin)
    end

    def create_intake_users
      ["Mail Intake", "Admin Intake"].each do |role|
        # do not try to recreate when running seed file after inital seed
        next if User.find_by_css_id("#{role.tr(' ', '')}_LOCAL".upcase)

        create(:user, css_id: "#{role.tr(' ', '')}_LOCAL", roles: [role], full_name: "Jame Local #{role} Smith")
      end
    end

    def create_vha_admins
      %w[VHAADMIN VHAADMIN2].each do |css_id|
        vha_admin_user = create(
          :user,
          css_id: css_id,
          full_name: css_id,
          roles: ["System Admin", "Certify Appeal", "Mail Intake", "Admin Intake"]
        )

        OrganizationsUser.make_user_admin(vha_admin_user, VhaBusinessLine.singleton)
      end
    end

    def create_colocated_users
      secondary_user = create(:user, full_name: "Harper SecondaryVLJSupportStaff Tash", roles: %w[Reader])
      create(:staff, :colocated_role, user: secondary_user, sdept: "DSP")
      Colocated.singleton.add_user(secondary_user)

      user = create(:user, css_id: "BVALSPORER", full_name: "Laura Co-located_Cases Sporer", roles: %w[Reader])
      create(:staff, :colocated_role, user: user, sdept: "DSP")
      Colocated.singleton.add_user(user)

      admin = create(:user, css_id: "VLJ_SUPPORT_ADMIN", full_name: "John VLJSupportAdmin Smith", roles: %w[Reader])
      create(:staff, :colocated_role, user: admin, sdept: "DSP")
      OrganizationsUser.make_user_admin(admin, Colocated.singleton)
    end

    def create_vso_users_and_tasks
      vso = create(:vso, name: "VSO", url: "veterans-service-organization", participant_id: "2452415")

      %w[BILLIE MICHAEL JIMMY].each do |name|
        u = create(:user, css_id: "#{name}_VSO",
                          full_name: "#{name} VSOUser Jones",
                          roles: %w[VSO],
                          email: "#{name}@test.com")
        vso.add_user(u)

        # Assign one IHP task to each member of the VSO team and leave some IHP tasks assigned to the organization.
        [true, false].each do |assign_to_user|
          a = create(:appeal)
          root_task = create(:root_task, appeal: a)
          create(:hearing, appeal: a)
          ihp_task = create(:informal_hearing_presentation_task, parent: root_task, appeal: a, assigned_to: vso)
          create(:track_veteran_task, parent: root_task, appeal: a, assigned_to: vso)

          next unless assign_to_user

          InformalHearingPresentationTask.create_many_from_params([{
                                                                    parent_id: ihp_task.id,
                                                                    assigned_to_id: u.id,
                                                                    assigned_to_type: User.name
                                                                  }], u)
        end
      end
    end

    def create_judge_teams
      DEVELOPMENT_JUDGE_TEAMS.each_pair do |judge_css_id, h|
        judge = User.find_or_create_by(css_id: judge_css_id, station_id: 101)
        judge.roles = judge.roles << "Hearing Prep" unless judge.roles.include?("Hearing Prep")
        judge.save!
        create(:staff, :judge_role) if judge.vacols_staff.nil?
        judge_team = JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)
        h[:attorneys].each do |css_id|
          judge_team.add_user(User.find_or_create_by(css_id: css_id, station_id: 101))
        end
      end
    end

    def create_dvc_teams
      DEVELOPMENT_DVC_TEAMS.each_pair do |dvc_css_id, judges|
        dvc = User.find_or_create_by(css_id: dvc_css_id, station_id: 101)
        dvc_team = DvcTeam.for_dvc(dvc) || DvcTeam.create_for_dvc(dvc)
        judges.each do |css_id|
          dvc_team.add_user(User.find_or_create_by(css_id: css_id, station_id: 101))
        end
      end
    end

    def create_transcription_team
      transcription_member_1 = create(:user, css_id: "TRANSCRIPTION_USER", full_name: "Noel TranscriptionUser Vasquez")
      TranscriptionTeam.singleton.add_user(transcription_member_1)

      transcription_member_2 = create(:user, css_id: "TRANSCRIPTION_USER_ALTERNATE", full_name: "Nathan TranscriptionUser Vasquez")
      TranscriptionTeam.singleton.add_user(transcription_member_2)
    end

    def create_hearings_user
      hearings_member = User.find_by(css_id: "BVATWARNER")
      HearingsManagement.singleton.add_user(hearings_member)
      HearingAdmin.singleton.add_user(hearings_member)
    end

    def create_build_and_edit_hearings_users
      roles = ["Edit HearSched", "Build HearSched"]
      user_params = [
        { css_id: "BVASYELLOW", station_id: 101, full_name: "Stacy BuildAndEditHearingSchedule Yellow", roles: roles },
        { css_id: "BVASORANGE", station_id: 343, full_name: "Felicia BuildAndEditHearingSchedule Orange", roles: roles }
      ]
      user_params.each do |params|
        user = create(:user, **params)
        HearingsManagement.singleton.add_user(user)
        HearingAdmin.singleton.add_user(user)
      end
    end

    def create_non_admin_hearing_coordinator_user
      hearings_user = create(:user,
                             css_id: "BVANHALE",
                             full_name: "Nisha NonAdminHearingCoordinator Hale",
                             roles: ["Edit HearSched"])
      HearingsManagement.singleton.add_user(hearings_user)
    end

    # Creates a VSO org for the PARALYZED VETERANS OF AMERICA VSO that the fake BGS
    # service returns.
    #
    # Use the participant ID `CLAIMANT_WITH_PVA_AS_VSO` to tie this org to a
    # claimant.
    def create_pva_vso_and_users
      vso = create(:vso,
                   name: "PARALYZED VETERANS OF AMERICA, INC.",
                   url: "paralyzed-veteran-of-america",
                   participant_id: "2452383")

      %w[WINNIE].each do |name|
        u = create(:user, css_id: "#{name}_PVA_VSO", full_name: "#{name} PVA_VSOUser James", roles: %w[VSO])
        vso.add_user(u)
      end
    end

    def create_field_vso_and_users
      vso = FieldVso.find_or_create_by(name: "Field VSO", url: "field-vso")

      %w[MANDY NICHOLAS ELIJAH].each do |name|
        u = create(:user,
                   css_id: "#{name}_VSO",
                   station_id: 101,
                   full_name: "#{name} VSOUser Wilson",
                   roles: %w[VSO])
        vso.add_user(u)

        a = create(:appeal)
        root_task = create(:root_task, appeal: a)
        create(:track_veteran_task, parent: root_task, appeal: a, assigned_to: vso)
      end
    end

    def create_org_queue_users
      nca = BusinessLine.find_or_create_by(name: "National Cemetery Administration", url: "nca")
      %w[Parveen Chandra Sydney Tai Kennedy].each do |name|
        u = create(:user, css_id: "NCA_QUEUE_USER_#{name}", full_name: "#{name} NCAUser Carter")
        nca.add_user(u)
      end

      %w[Kun Casey Ariel Naomi Kelly].each do |name|
        u = create(:user, css_id: "ORG_QUEUE_USER_#{name}", full_name: "#{name} TranslationUser Cullen")
        Translation.singleton.add_user(u)
      end
    end

    def create_qr_user
      qr_user = create(:user, css_id: "QR_USER", full_name: "Yarden QualityReviewer Jordan")
      QualityReview.singleton.add_user(qr_user)
    end

    def create_aod_user_and_tasks
      u = create(:user, css_id: "AOD_USER", full_name: "Shiloh AODUser Villar")
      AodTeam.singleton.add_user(u)

      root_task = create(:root_task)
      mail_task = create(:aod_motion_mail_task, appeal: root_task.appeal, parent_id: root_task.id)
      create(:aod_motion_mail_task, appeal: root_task.appeal, parent_id: mail_task.id)
    end

    def create_privacy_user
      u = create(:user, css_id: "PRIVACY_TEAM_USER", full_name: "Leighton PrivacyAndFOIAUser Naumov")
      PrivacyTeam.singleton.add_user(u)
    end

    def create_lit_support_user
      u = create(:user, css_id: "LIT_SUPPORT_USER", full_name: "Kiran LitigationSupportUser Rider")
      LitigationSupport.singleton.add_user(u)
    end

    def create_oai_team_user
      u = create(:user, css_id: "OAI_TEAM_USER", full_name: "Tywin OaiTeam Lannister")
      OrganizationsUser.make_user_admin(u, OaiTeam.singleton)
    end

    def create_occ_team_user
      user1 = create(:user, css_id: "OCC_TEAM_USER", full_name: "Jon OccTeam Snow")
      OrganizationsUser.make_user_admin(user1, OccTeam.singleton)
      user2 = create(:user, css_id: "OCC_OAI_TEAM_USER", full_name: "Ned OccOaiTeam Stark")
      OccTeam.singleton.add_user(user2)
      OaiTeam.singleton.add_user(user2)
    end

    def create_cavc_lit_support_user
      users_info = [
        { css_id: "CAVC_LIT_SUPPORT_ADMIN", full_name: "Diego CAVCLitSupportAdmin Christiansen" },
        { css_id: "CAVC_LIT_SUPPORT_ADMIN2", full_name: "Mattie CAVCLitSupportAdmin Jackson" },
        { css_id: "CAVC_LIT_SUPPORT_USER1", full_name: "Regina CAVCLitSupportUser Lebsack" },
        { css_id: "CAVC_LIT_SUPPORT_USER2", full_name: "Tonita CAVCLitSupportUser Kuhn" },
        { css_id: "CAVC_LIT_SUPPORT_USER3", full_name: "Anna CAVCLitSupportUser Cooper" },
        { css_id: "CAVC_LIT_SUPPORT_USER4", full_name: "Ramona CAVCLitSupportUser Stanley" },
        { css_id: "CAVC_LIT_SUPPORT_USER5", full_name: "Drew CAVCLitSupportUser Payne" },
        { css_id: "CAVC_LIT_SUPPORT_USER6", full_name: "Clyde CAVCLitSupportUser Lee" },
        { css_id: "CAVC_LIT_SUPPORT_USER7", full_name: "Priscilla CAVCLitSupportUser Cortez" },
        { css_id: "CAVC_LIT_SUPPORT_USER8", full_name: "Irvin CAVCLitSupportUser King" }
      ]

      users = users_info.map do |user_info|
        create(:user, css_id: user_info[:css_id], full_name: user_info[:full_name])
      end

      users.each { |u| CavcLitigationSupport.singleton.add_user(u) }
      OrganizationsUser.make_user_admin(users.first, CavcLitigationSupport.singleton)
      OrganizationsUser.make_user_admin(users.second, CavcLitigationSupport.singleton)
    end

    def create_pulac_cerullo_user
      u = create(:user, css_id: "BVAKSOSNA", full_name: "KATHLEEN PulacCerulloUser SOSNA")
      PulacCerullo.singleton.add_user(u)
    end

    def create_mail_team_user
      u = create(:user, css_id: "JOLLY_POSTMAN", full_name: "Huan MailUser Tiryaki")
      MailTeam.singleton.add_user(u)
    end

    def create_clerk_of_the_board_users
      atty = create(
        :user,
        :with_vacols_attorney_record,
        css_id: "COB_USER",
        full_name: "Clark ClerkOfTheBoardUser Bard",
        roles: ["Hearing Prep", "Mail Intake"]
      )
      ClerkOfTheBoard.singleton.add_user(atty)

      judge = create(:user, :with_vacols_judge_record, full_name: "Judith COTB Judge", css_id: "BVACOTBJUDGE",
                                                       roles: ["Hearing Prep", "Mail Intake"])
      ClerkOfTheBoard.singleton.add_user(judge)

      admin = create(:user, full_name: "Ty ClerkOfTheBoardAdmin Cobb", css_id: "BVATCOBB",
                            roles: ["Hearing Prep", "Mail Intake"])
      OrganizationsUser.make_user_admin(admin, ClerkOfTheBoard.singleton)

      # added to Bva Intake so they can intake
      BvaIntake.singleton.add_user(atty)
      BvaIntake.singleton.add_user(judge)
      BvaIntake.singleton.add_user(admin)
    end

    def create_case_search_only_user
      create(:user, css_id: "CASE_SEARCHER_ONLY", full_name: "Blair CaseSearchAccessNoQueueAccess Lyon")
    end

    def create_split_appeals_test_users
      ussc = create(:user,
                    css_id: "SPLTAPPLSNOW",
                    full_name: "Jon SupervisorySeniorCounselUser Snow",
                    roles: ["Hearing Prep"])
      SupervisorySeniorCounsel.singleton.add_user(ussc)
      ussc2 = create(:user,
                     css_id: "SPLTAPPLTARGARYEN",
                     full_name: "Daenerys SupervisorySeniorCounselUser Targaryen",
                     roles: ["Hearing Prep"])
      SupervisorySeniorCounsel.singleton.add_user(ussc2)
      ussccr = create(:user,
                      css_id: "SPLTAPPLLANNISTER",
                      full_name: "Jaime SupervisorySeniorCounselCaseReviewUser Lannister",
                      roles: ["Hearing Prep"])
      SupervisorySeniorCounsel.singleton.add_user(ussccr)
      CaseReview.singleton.add_user(ussccr)
      ussccr2 = create(:user,
                       css_id: "SPLTAPPLSTARK",
                       full_name: "Ned SupervisorySeniorCounselCaseReviewUser Stark",
                       roles: ["Hearing Prep"])
      SupervisorySeniorCounsel.singleton.add_user(ussccr2)
      CaseReview.singleton.add_user(ussccr2)
    end

    def add_mail_intake_to_all_bva_intake_users
      bva_intake = BvaIntake.singleton
      new_role = "Mail Intake"
      bva_intake.users.each do |user|
        user_roles = user.roles
        unless user_roles.include?(new_role)
          new_roles = user_roles << new_role
          user.update!(roles: new_roles)
        end
      end
    end

    def create_and_add_cda_control_group_users
      leo = create(:user, css_id: "CDAADMINLEO",
                          full_name: "Leonardo CDAC_Admin Turtur",
                          roles: ["Mail Intake"])
      OrganizationsUser.make_user_admin(leo, CDAControlGroup.singleton)

      casey = create(:user, css_id: "CDAUSERCASEY",
                            full_name: "Casey CDAC_User Jones",
                            roles: ["Mail Intake"])
      CDAControlGroup.singleton.add_user(casey)

      CDAControlGroup.singleton.add_user(User.find_by(css_id: "BVAEBECKER"))
      CDAControlGroup.singleton.add_user(User.find_by(css_id: "BVAKKEELING"))
      OrganizationsUser.make_user_admin(User.find_by(css_id: "BVADWISE"), CDAControlGroup.singleton)
    end

    def add_users_to_bva_dispatch
      # These users are created earlier in this file
      BvaDispatch.singleton.add_user(User.find_by(css_id: "BVAGWHITE"))
      BvaDispatch.singleton.add_user(User.find_by(css_id: "BVAGBLACK"))
    end

    def setup_camo_org
      regular_user = create(:user, full_name: "Greg CAMOUser Camo", css_id: "CAMOUSER")
      admin_user = create(:user, full_name: "Alex CAMOAdmin Camo", css_id: "CAMOADMIN")
      VhaCamo.singleton.add_user(regular_user)
      OrganizationsUser.make_user_admin(admin_user, VhaCamo.singleton)
    end

    def setup_caregiver_org
      regular_user = create(:user, full_name: "Edward CSPUser Caregiver", css_id: "CAREGIVERUSER")
      admin_user = create(:user, full_name: "Alvin CSPAdmin Caregiver", css_id: "CAREGIVERADMIN")
      VhaCaregiverSupport.singleton.add_user(regular_user)
      OrganizationsUser.make_user_admin(admin_user, VhaCaregiverSupport.singleton)
    end

    def setup_program_offices
      PROGRAM_OFFICES.each { |name| VhaProgramOffice.create!(name: name, url: name) }

      regular_user = create(:user, full_name: "Stevie VhaProgramOffice Amana", css_id: "VHAPOUSER")
      admin_user = create(:user, full_name: "Channing VhaProgramOfficeAdmin Katz", css_id: "VHAPOADMIN")

      VhaProgramOffice.all.each do |org|
        org.add_user(regular_user)
        OrganizationsUser.make_user_admin(admin_user, org)
      end
    end

    def setup_specialty_case_team
      regular_user = create(:user, full_name: "Ron SCTUser SCT", css_id: "SCTUSER")
      admin_user = create(:user, full_name: "Adam SCTAdmin SCT", css_id: "SCTADMIN")
      SpecialtyCaseTeam.singleton.add_user(regular_user)
      OrganizationsUser.make_user_admin(admin_user, SpecialtyCaseTeam.singleton)
    end

    def create_visn_org_teams
      regular_user = create(:user, full_name: "Stacy VISNUser Smith", css_id: "VISNUSER")
      admin_user = create(:user, full_name: "Betty VISNAdmin Rose", css_id: "VISNADMIN")

      Constants.VISN_ORG_NAMES.visn_orgs.name.each do |name|
        visn = VhaRegionalOffice.create!(name: name, url: name)
        visn.add_user(regular_user)
        OrganizationsUser.make_user_admin(admin_user, visn)
      end
    end

    def setup_emo_org
      regular_user = create(:user, full_name: "Paul EMOUser EMO", css_id: "EMOUSER")
      admin_user = create(:user, full_name: "Julie EMOAdmin EMO", css_id: "EMOADMIN")
      EducationEmo.singleton.add_user(regular_user)
      OrganizationsUser.make_user_admin(admin_user, EducationEmo.singleton)
    end

    def setup_rpo_orgs
      RPOS.each { |name| EducationRpo.create!(name: name, url: name) }

      regular_user = create(:user, full_name: "Peter EDURPOUSER Campbell", css_id: "EDURPOUSER")
      admin_user = create(:user, full_name: "Samuel EDURPOADMIN Clemens", css_id: "EDURPOADMIN")

      EducationRpo.all.each do |org|
        org.add_user(regular_user)
        OrganizationsUser.make_user_admin(admin_user, org)
      end
    end

    def create_singleton_organizations
      Organization.subclasses.map { |subclass| subclass.singleton if subclass.respond_to?(:singleton) }
    end

    def create_qa_test_users
      create(:user, :with_vacols_titled_attorney_record, css_id: "QATTY1", full_name: "QA Attorney_1")
      create(:user, :with_vacols_titled_attorney_record, css_id: "QATTY2", full_name: "QA Attorney_2")
      create(:user, :with_vacols_titled_attorney_record, css_id: "QATTY3", full_name: "QA Attorney_3")
      create(:user, :judge_inactive, :with_inactive_vacols_judge_record,
             css_id: "QINELIGVLJ", full_name: "QA Ineligible Judge")
      create(:user, :judge, :with_vacols_judge_record,
             css_id: "QACTVLJNOTM", full_name: "QA_Active_Judge With No_Team")

      # below users are created and added to organizations
      create_qa_ssc_avlj_attorney
      create_qa_nonssc_avlj_attorney
      create_qa_cob_intake_clerk
      create_qa_intake_clerk
      create_qa_intake_admin
      create_qa_hearing_admin
      create_qa_case_movement_user
      create_qa_judge_team_3
      create_qa_judge_team_2
    end

    def create_qa_ssc_avlj_attorney
      atty = create(:user, css_id: "QSSCAVLJ", full_name: "QA SSC_AVLJ Attorney", roles: ["Hearing Prep"])
      SupervisorySeniorCounsel.singleton.add_user(atty)
      create(:staff, user: atty, sattyid: "9999", smemgrp: "9999")
    end

    def create_qa_nonssc_avlj_attorney
      atty = create(:user, css_id: "QNONSSCAVLJ", full_name: "QA Non_SSC_AVLJ Attorney")
      create(:staff, user: atty, sattyid: "9998", smemgrp: "9998")
    end

    def create_qa_cob_intake_clerk
      clerk = create(
        :user,
        css_id: "QCOBINTAKE",
        full_name: "QA Clerk_of_the_Board",
        roles: ["Hearing Prep", "Mail Intake"]
      )
      OrganizationsUser.make_user_admin(clerk, ClerkOfTheBoard.singleton)
      BvaIntake.singleton.add_user(clerk)
    end

    def create_qa_intake_clerk
      clerk = create(:user, css_id: "QINTAKE", full_name: "QA Intake Clerk", roles: ["Mail Intake"])
      BvaIntake.singleton.add_user(clerk)
    end

    def create_qa_intake_admin
      admin = create(:user, css_id: "QINTAKEADMIN", full_name: "QA Intake Admin", roles: ["Mail Intake"])
      OrganizationsUser.make_user_admin(admin, BvaIntake.singleton)
      OrganizationsUser.make_user_admin(admin, CDAControlGroup.singleton)
    end

    def create_qa_hearing_admin
      create(:user,
             css_id: "QHEARADMIN",
             station_id: 343,
             full_name: "QA Hearings Admin",
             roles: ["Edit HearSched", "Build HearSched"])
    end

    def create_qa_case_movement_user
      user = create(:user, :with_vacols_record, css_id: "QCASEMVMT", full_name: "QA Case Movement")
      OrganizationsUser.make_user_admin(user, SpecialCaseMovementTeam.singleton)
    end

    def create_qa_judge_team_3
      qa_judge_3 = create(:user, :judge, :with_vacols_judge_record,
                          css_id: "QACTIVEVLJ3", full_name: "QA_Active_Judge With Team_of_3")
      qa_judge_team_3 = JudgeTeam.for_judge(qa_judge_3)
      qa_judge_team_3.add_user(User.find_by(css_id: "QATTY1"))
      qa_judge_team_3.add_user(User.find_by(css_id: "QATTY2"))
      qa_judge_team_3.add_user(User.find_by(css_id: "QATTY3"))
    end

    def create_qa_judge_team_2
      qa_judge_2 = create(:user, :judge, :with_vacols_judge_record,
                          css_id: "QACTIVEVLJ2", full_name: "QA_Active_Judge With Team_of_2")
      qa_judge_team_2 = JudgeTeam.for_judge(qa_judge_2)
      qa_judge_team_2.add_user(User.find_by(css_id: "QATTY1"))
      qa_judge_team_2.add_user(User.find_by(css_id: "QATTY2"))
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/ClassLength
  end
end
