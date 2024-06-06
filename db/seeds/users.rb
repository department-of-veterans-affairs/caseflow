# frozen_string_literal: true

# Create Users/Organizations used by other seed classes.

module Seeds
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
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

    def seed!
      create_users
    end

    private

    def create_users
      create_batch_1_users
      create_bvaebecker #Judge_CaseToAssign
      create_bvakkeeling #Judge_CaseToAssign_NoTeam
      create_batch_2_users
      create_dispatch_admin
      create_case_review_admin
      create_special_case_movement_user
      create_bvadwise #Intake Admin
      create_bva_intake_user

      Functions.grant!("System Admin", users: User.all.pluck(:css_id))

      create_vha_admins
      create_team_admin
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
      create_inbound_ops_team_user
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
      create_cda_control_group_users
      create_qa_test_users
    end

    def create_batch_1_users
      User.find_or_create_by(css_id: "CASEFLOW1", station_id: 317, full_name: "System User")
      User.find_or_create_by(css_id: "BVASCASPER1", station_id: 101, full_name: "Steve Attorney_Cases_AVLJ Casper")
      User.find_or_create_by(css_id: "BVASRITCHIE", station_id: 101, full_name: "Sharree AttorneyNoCases Ritchie")
      User.find_or_create_by(css_id: "BVAAABSHIRE", station_id: 101, full_name: "Aaron Judge_HearingsAndCases Abshire")
      User.find_or_create_by(css_id: "BVARERDMAN", station_id: 101, full_name: "Rachael JudgeHasAttorneys_Cases_AVLJ Erdman")
    end

    def create_bvaebecker
      bvaebecker = User.find_or_create_by(css_id: "BVAEBECKER", station_id: 101, full_name: "Elizabeth Judge_CaseToAssign Becker")
      CDAControlGroup.singleton.add_user(bvaebecker)
    end

    def create_bvakkeeling
      bvakkeeling = User.find_or_create_by(css_id: "BVAKKEELING", station_id: 101, full_name: "Keith Judge_CaseToAssign_NoTeam Keeling")
      CDAControlGroup.singleton.add_user(bvakkeeling)
    end

    def create_batch_2_users
      User.find_or_create_by(css_id: "BVAAWAKEFIELD", station_id: 101, full_name: "Apurva Judge_CaseAtDispatch Wakefield")
      User.find_or_create_by(css_id: "BVAABELANGER", station_id: 101, full_name: "Andy Attorney_CaseAtDispatch Belanger")
      User.find_or_create_by(css_id: "BVATWARNER", station_id: 101, full_name: "Theresa BuildHearingSchedule Warner")
      User.find_or_create_by(css_id: "BVAGWHITE", station_id: 101, full_name: "George BVADispatchUser_Cases White")
      User.find_or_create_by(css_id: "BVAGGREY", station_id: 101, full_name: "Gina BVADispatchUser_NoCases Grey")
      User.find_or_create_by(css_id: "BVATCOLLIER", station_id: 101, full_name: "Tonja DVCTeam Collier")
    end

    def create_dispatch_admin
      dispatch_admin = User.find_or_create_by(
        css_id: "BVAGBLACK",
        station_id: 101,
        full_name: "Geoffrey BVADispatchAdmin_NoCases Black"
      )
      OrganizationsUser.make_user_admin(dispatch_admin, BvaDispatch.singleton)
    end

    def create_case_review_admin
      case_review_admin = User.find_or_create_by(css_id: "BVAKBLUE", station_id: 101, full_name: "Kim CaseReviewAdmin Blue")
      OrganizationsUser.make_user_admin(case_review_admin, CaseReview.singleton)
    end

    def create_special_case_movement_user
      special_case_movement_user = User.find_or_create_by(
        css_id: "BVARDUNKLE",
        station_id: 101,
        full_name: "Rosalie SpecialCaseMovement Dunkle"
      )
      FactoryBot.create(:staff, user: special_case_movement_user)
      SpecialCaseMovementTeam.singleton.add_user(special_case_movement_user)
    end

    def special_case_movement_admin
      special_case_movement_admin = User.find_or_create_by(css_id: "BVAGBEEKMAN",
                                                station_id: 101,
                                                full_name: "Bryan SpecialCaseMovementAdmin Beekman")
      FactoryBot.create(:staff, user: special_case_movement_admin)
      OrganizationsUser.make_user_admin(special_case_movement_admin, SpecialCaseMovementTeam.singleton)
    end

    def create_bva_intake_user
      bva_intake_user = User.find_or_create_by(css_id: "BVAISHAW", station_id: 101, full_name: "Ignacio BvaIntakeUser Shaw")
      BvaIntake.singleton.add_user(bva_intake_user)
    end

    def create_bvadwise
      bva_intake_admin = User.find_or_create_by(css_id: "BVADWISE", station_id: 101, full_name: "Deborah BvaIntakeAdmin Wise")
      OrganizationsUser.make_user_admin(bva_intake_admin, BvaIntake.singleton)
      OrganizationsUser.make_user_admin(bva_intake_admin, CDAControlGroup.singleton)
    end

    def create_vha_admins
      %w[VHAADMIN VHAADMIN2].each do |css_id|
        vha_admin_user = User.find_or_create_by(
          css_id: css_id,
          station_id: 101,
          full_name: css_id,
          roles: ["System Admin", "Certify Appeal", "Mail Intake", "Admin Intake"]
        )

        OrganizationsUser.make_user_admin(vha_admin_user, VhaBusinessLine.singleton)
      end
    end

    def create_team_admin
      u = User.find_or_create_by(css_id: "TEAM_ADMIN", station_id: 101, full_name: "Jim TeamAdminSystemAdmin Jones")
      existing_sysadmins = Functions.details_for("System Admin")[:granted] || []
      Functions.grant!("System Admin", users: existing_sysadmins + [u.css_id])
      Bva.singleton.add_user(u)
    end

    def create_colocated_users
      secondary_user = create(:user, full_name: "Harper SecondaryVLJSupportStaff Tash", roles: %w[Reader])
      create(:staff, :colocated_role, user: secondary_user, sdept: "DSP")
      Colocated.singleton.add_user(secondary_user)

      user = User.find_or_create_by(
        css_id: "BVALSPORER",
        station_id: 101,
        full_name: "Laura Co-located_Cases Sporer",
        roles: %w[Reader]
      )
      create(:staff, :colocated_role, user: user, sdept: "DSP")
      Colocated.singleton.add_user(user)

      admin = User.find_or_create_by(
        css_id: "VLJ_SUPPORT_ADMIN",
        station_id: 101,
        full_name: "John VLJSupportAdmin Smith",
        roles: %w[Reader]
      )
      create(:staff, :colocated_role, user: admin, sdept: "DSP")
      OrganizationsUser.make_user_admin(admin, Colocated.singleton)
    end

    def create_vso_users_and_tasks
      vso = Vso.create(
        name: "VSO",
        url: "veterans-service-organization",
        participant_id: "2452415"
      )

      %w[BILLIE MICHAEL JIMMY].each do |name|
        u = User.find_or_create_by(
          css_id: "#{name}_VSO",
          station_id: 101,
          full_name: "#{name} VSOUser Jones",
          roles: %w[VSO],
          email: "#{name}@test.com"
        )
        vso.add_user(u)

        # Assign one IHP task to each member of the VSO team and leave some IHP tasks assigned to the organization.
        if u.tasks.nil?
          [true, false].each do |assign_to_user|
            a = create(:appeal)
            root_task = create(:root_task, appeal: a)
            create(
              :hearing,
              appeal: a
            )
            ihp_task = create(
              :informal_hearing_presentation_task,
              parent: root_task,
              appeal: a,
              assigned_to: vso
            )
            create(
              :track_veteran_task,
              parent: root_task,
              appeal: a,
              assigned_to: vso
            )

            next unless assign_to_user

            InformalHearingPresentationTask.create_many_from_params([{
                                                                      parent_id: ihp_task.id,
                                                                      assigned_to_id: u.id,
                                                                      assigned_to_type: User.name
                                                                    }], u)
          end
        end
      end
    end

    def create_judge_teams
      DEVELOPMENT_JUDGE_TEAMS.each_pair do |judge_css_id, h|
        judge = User.find_or_create_by(css_id: judge_css_id, station_id: 101)
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
      transcription_member = User.find_or_create_by(
        css_id: "TRANSCRIPTION_USER",
        station_id: 101,
        full_name: "Noel TranscriptionUser Vasquez"
      )
      TranscriptionTeam.singleton.add_user(transcription_member)
    end

    def create_hearings_user
      hearings_member = User.find_or_create_by(css_id: "BVATWARNER", station_id: 101)
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
        user = User.find_or_create_by(**params)
        HearingsManagement.singleton.add_user(user)
        HearingAdmin.singleton.add_user(user)
      end
    end

    def create_non_admin_hearing_coordinator_user
      hearings_user = User.find_or_create_by(
        css_id: "BVANHALE",
        station_id: 101,
        full_name: "Nisha NonAdminHearingCoordinator Hale",
        roles: ["Edit HearSched"]
      )
      HearingsManagement.singleton.add_user(hearings_user)
    end

    # Creates a VSO org for the PARALYZED VETERANS OF AMERICA VSO that the fake BGS
    # service returns.
    #
    # Use the participant ID `CLAIMANT_WITH_PVA_AS_VSO` to tie this org to a
    # claimant.
    def create_pva_vso_and_users
      vso = Vso.create(
        name: "PARALYZED VETERANS OF AMERICA, INC.",
        url: "paralyzed-veteran-of-america",
        participant_id: "2452383"
      )

      %w[WINNIE].each do |name|
        u = User.find_or_create_by(
          css_id: "#{name}_PVA_VSO",
          station_id: 101,
          full_name: "#{name} PVA_VSOUser James",
          roles: %w[VSO]
        )
        vso.add_user(u)
      end
    end

    def create_field_vso_and_users
      vso = FieldVso.find_or_create_by(name: "Field VSO", url: "field-vso")

      %w[MANDY NICHOLAS ELIJAH].each do |name|
        u = User.find_or_create_by(
          css_id: "#{name}_VSO",
          station_id: 101,
          full_name: "#{name} VSOUser Wilson",
          roles: %w[VSO]
        )
        vso.add_user(u)

        a = create(:appeal)
        root_task = create(:root_task, appeal: a)
        create(
          :track_veteran_task,
          parent: root_task,
          appeal: a,
          assigned_to: vso
        )
      end
    end

    def create_org_queue_users
      nca = BusinessLine.find_or_create_by!(name: "National Cemetery Administration", url: "nca")
      %w[Parveen Chandra Sydney Tai Kennedy].each do |name|
        u = User.find_or_create_by!(station_id: 101, css_id: "NCA_QUEUE_USER_#{name.upcase}", full_name: "#{name} NCAUser Carter")
        nca.add_user(u)
      end

      %w[Kun Casey Ariel Naomi Kelly].each do |name|
        u = User.find_or_create_by!(station_id: 101, css_id: "ORG_QUEUE_USER_#{name.upcase}", full_name: "#{name} TranslationUser Cullen")
        Translation.singleton.add_user(u)
      end
    end

    def create_qr_user
      qr_user = User.find_or_create_by!(station_id: 101, css_id: "QR_USER", full_name: "Yarden QualityReviewer Jordan")
      QualityReview.singleton.add_user(qr_user)
    end

    def create_aod_user_and_tasks
      u = User.find_or_create_by!(station_id: 101, css_id: "AOD_USER", full_name: "Shiloh AODUser Villar")
      AodTeam.singleton.add_user(u)

      root_task = create(:root_task)
      mail_task = ::AodMotionMailTask.create!(
        appeal: root_task.appeal,
        parent_id: root_task.id,
        assigned_to: MailTeam.singleton
      )
      ::AodMotionMailTask.create!(
        appeal: root_task.appeal,
        parent_id: mail_task.id,
        assigned_to: AodTeam.singleton
      )
    end

    def create_privacy_user
      u = User.find_or_create_by!(station_id: 101, css_id: "PRIVACY_TEAM_USER", full_name: "Leighton PrivacyAndFOIAUser Naumov")
      PrivacyTeam.singleton.add_user(u)
    end

    def create_lit_support_user
      u = User.find_or_create_by!(station_id: 101, css_id: "LIT_SUPPORT_USER", full_name: "Kiran LitigationSupportUser Rider")
      LitigationSupport.singleton.add_user(u)
    end

    def create_oai_team_user
      u = User.find_or_create_by!(station_id: 101, css_id: "OAI_TEAM_USER", full_name: "Tywin OaiTeam Lannister")
      OaiTeam.singleton.add_user(u)
      OrganizationsUser.make_user_admin(u, OaiTeam.singleton)
    end

    def create_occ_team_user
      u = User.find_or_create_by!(station_id: 101, css_id: "OCC_TEAM_USER", full_name: "Jon OccTeam Snow")
      OccTeam.singleton.add_user(u)
      OrganizationsUser.make_user_admin(u, OccTeam.singleton)
      u = User.find_or_create_by!(station_id: 101, css_id: "OCC_OAI_TEAM_USER", full_name: "Ned OccOaiTeam Stark")
      OccTeam.singleton.add_user(u)
      OaiTeam.singleton.add_user(u)
    end

    def create_inbound_ops_team_user
      u = User.create!(station_id: 101, css_id: "INBOUND_OPS_TEAM_ADMIN_USER", full_name: "Jon MailTeam Snow Admin")
      InboundOpsTeam.singleton.add_user(u)
      OrganizationsUser.make_user_admin(u, InboundOpsTeam.singleton)

      u = User.create!(station_id: 101, css_id: "INBOUND_OPS_TEAM_MAIL_INTAKE_USER",
        full_name: "Jon MailTeam Snow Mail Intake", roles: ["Mail Intake"])
      InboundOpsTeam.singleton.add_user(u)
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
        User.find_or_create_by!(station_id: 101,
                     css_id: user_info[:css_id],
                     full_name: user_info[:full_name])
      end

      users.each { |u| CavcLitigationSupport.singleton.add_user(u) }
      OrganizationsUser.make_user_admin(users.first, CavcLitigationSupport.singleton)
      OrganizationsUser.make_user_admin(users.second, CavcLitigationSupport.singleton)
    end

    def create_pulac_cerullo_user
      u = User.find_or_create_by!(station_id: 101, css_id: "BVAKSOSNA", full_name: "KATHLEEN PulacCerulloUser SOSNA")
      PulacCerullo.singleton.add_user(u)
    end

    def create_mail_team_user
      u = User.find_or_create_by!(station_id: 101, css_id: "JOLLY_POSTMAN", full_name: "Huan MailUser Tiryaki")
      MailTeam.singleton.add_user(u)
    end

    def create_clerk_of_the_board_users

      atty = User.find_by(css_id: "COB_USER")  ||
        create(
          :user,
          :with_vacols_attorney_record,
          station_id: 101,
          css_id: "COB_USER",
          full_name: "Clark ClerkOfTheBoardUser Bard",
          roles: ["Hearing Prep", "Mail Intake"]
        )
      ClerkOfTheBoard.singleton.add_user(atty)

      judge = User.find_or_create_by(full_name: "Judith COTB Judge", station_id: 101, css_id: "BVACOTBJUDGE", roles: ["Hearing Prep", "Mail Intake"])
      create(:staff, :judge_role, sdomainid: judge.css_id)
      ClerkOfTheBoard.singleton.add_user(judge)

      admin = User.find_or_create_by!(full_name: "Ty ClerkOfTheBoardAdmin Cobb", station_id: 101, css_id: "BVATCOBB", roles: ["Hearing Prep", "Mail Intake"])
      ClerkOfTheBoard.singleton.add_user(admin)
      OrganizationsUser.make_user_admin(admin, ClerkOfTheBoard.singleton)

      # added to Bva Intake so they can intake
      BvaIntake.singleton.add_user(atty)
      BvaIntake.singleton.add_user(judge)
      BvaIntake.singleton.add_user(admin)
    end

    def create_case_search_only_user
      User.find_or_create_by!(station_id: 101, css_id: "CASE_SEARCHER_ONLY", full_name: "Blair CaseSearchAccessNoQueueAccess Lyon")
    end

    def create_split_appeals_test_users
      ussc = User.find_or_create_by!(station_id: 101,
                          css_id: "SPLTAPPLSNOW",
                          full_name: "Jon SupervisorySeniorCouncilUser Snow",
                          roles: ["Hearing Prep"])
      SupervisorySeniorCouncil.singleton.add_user(ussc)
      ussc2 = User.find_or_create_by!(station_id: 101,
                           css_id: "SPLTAPPLTARGARYEN",
                           full_name: "Daenerys SupervisorySeniorCouncilUser Targaryen",
                           roles: ["Hearing Prep"])
      SupervisorySeniorCouncil.singleton.add_user(ussc2)
      ussccr = User.find_or_create_by!(station_id: 101,
                            css_id: "SPLTAPPLLANNISTER",
                            full_name: "Jaime SupervisorySeniorCouncilCaseReviewUser Lannister",
                            roles: ["Hearing Prep"])
      SupervisorySeniorCouncil.singleton.add_user(ussccr)
      CaseReview.singleton.add_user(ussccr)
      ussccr2 = User.find_or_create_by!(station_id: 101,
                             css_id: "SPLTAPPLSTARK",
                             full_name: "Ned SupervisorySeniorCouncilCaseReviewUser Stark",
                             roles: ["Hearing Prep"])
      SupervisorySeniorCouncil.singleton.add_user(ussccr2)
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

    def create_cda_control_group_users
      bvaebeckser = User.find_or_create_by!(station_id: 101,
                                  css_id: "BVAEBECKSER",
                                  full_name: "Elizabeth Judge_VaseToAssign Becker",
                                  roles: ["Mail Intake"])
      CDAControlGroup.singleton.add_user(bvaebeckser)

      leo = User.find_or_create_by!(station_id: 101,
                          css_id: "CDAADMINLEO",
                          full_name: "Leonardo CDAC_Admin Turtur",
                          roles: ["Mail Intake"])
      CDAControlGroup.singleton.add_user(leo)
      OrganizationsUser.make_user_admin(leo, CDAControlGroup.singleton)
      casey = User.find_or_create_by!(station_id: 101,
                            css_id: "CDAUSERCASEY",
                            full_name: "Casey CDAC_User Jones",
                            roles: ["Mail Intake"])
      CDAControlGroup.singleton.add_user(casey)

      create_qa_admin_for_cda_control_group
    end

    def create_qa_admin_for_cda_control_group
      qa_admin = create(:user, :judge, :with_vacols_judge_record,
                        css_id: "QAACDPLUS",
                        full_name: "QA_Admin ACD_CF TM_Mgmt_Intake",
                        roles: ["Mail Intake", "Admin Intake", "Hearing Prep"])

      # {CDA Control Group Admin}
      CDAControlGroup.singleton.add_user(qa_admin)
      OrganizationsUser.make_user_admin(qa_admin, CDAControlGroup.singleton)

      # {BVA Intake Admin}
      BvaIntake.singleton.add_user(qa_admin)
      OrganizationsUser.make_user_admin(qa_admin, BvaIntake.singleton)

      # {BVA Org Admin}
      existing_sysadmins = Functions.details_for("System Admin")[:granted] || []
      Functions.grant!("System Admin", users: existing_sysadmins + [qa_admin.css_id])
      Bva.singleton.add_user(qa_admin)
      OrganizationsUser.make_user_admin(qa_admin, Bva.singleton)

      # {Adds attorney so judge team can be targeted by Ama_affinity_cases.rb seed script}
      judge_team = JudgeTeam.for_judge(qa_admin) || JudgeTeam.create_for_judge(qa_admin)
      judge_team.add_user(User.find_by_css_id("BVASCASPER1"))
    end

    def create_qa_test_users
      create_qa_active_judge3
      create_qa_active_judge2
      create_qa_ineligible_judge
      create_qa_solo_active_judge
      create_qa_ssc_avlj_attorney
      create_qa_nonssc_avlj_attorney
      create_qa_cob_intake_clerk
      create_qa_intake_clerk
      create_qa_intake_admin
      create_qa_hearing_admin
      create_qa_case_movement_user
      create_qa_attny_1
      create_qa_attny_2
      create_qa_attny_3
      create_qa_judge_team_3
      create_qa_judge_team_2
    end

    def create_qa_active_judge3
      User.find_or_create_by(
        css_id: "QACTIVEVLJ3",
        station_id: 101,
        full_name: "QA_Active_Judge With Team_of_3"
      )
    end

    def create_qa_active_judge2
      User.find_or_create_by(
        css_id: "QACTIVEVLJ2",
        station_id: 101,
        full_name: "QA_Active_Judge With Team_of_2"
      )
    end

    def create_qa_ineligible_judge
      ineligible_judge = User.find_or_create_by(
        css_id: "QINELIGVLJ",
        station_id: 101,
        full_name: "QA Ineligible Judge",
        status: nil
      )
      create(
        :staff,
        :inactive_judge,
        slogid: ineligible_judge.css_id,
        user: ineligible_judge
      )
    end

    def create_qa_solo_active_judge
      solo_active_judge = User.find_or_create_by(
        css_id: "QACTVLJNOTM",
        station_id: 101,
        full_name: "QA_Active_Judge With No_Team"
      )
      create(
        :staff,
        :judge_role,
        slogid: solo_active_judge.css_id,
        user: solo_active_judge
      )
    end

    def create_qa_ssc_avlj_attorney
      qa_ssc_avlj_attorney = User.find_or_create_by(
        css_id: "QSSCAVLJ",
        station_id: 101,
        full_name: "QA SSC_AVLJ Attorney",
        roles: ["Hearing Prep"]
      )
      SupervisorySeniorCouncil.singleton.add_user(qa_ssc_avlj_attorney)
      VACOLS::Staff.create(
        snamef: "QA_SSC_AVLJ",
        snamel: "Attorney",
        sdomainid: qa_ssc_avlj_attorney.css_id,
        sattyid: "9999",
        smemgrp: "9999"
      )
    end

    def create_qa_nonssc_avlj_attorney
      qa_nonssc_avlj_attorney = User.find_or_create_by(
        css_id: "QNONSSCAVLJ",
        station_id: 101,
        full_name: "QA Non_SSC_AVLJ Attorney"
      )
      VACOLS::Staff.create(
        snamef: "QA_NonSSC_AVLJ",
        snamel: "Attorney",
        sdomainid: qa_nonssc_avlj_attorney.css_id,
        sattyid: "9998",
        smemgrp: "9998"
      )
    end

    def create_qa_cob_intake_clerk
      qa_cob_intake_clerk_user = User.find_or_create_by(
        css_id: "QCOBINTAKE",
        station_id: 101,
        full_name: "QA Clerk_of_the_Board",
        roles: ["Hearing Prep", "Mail Intake"]
      )
      ClerkOfTheBoard.singleton.add_user(qa_cob_intake_clerk_user)
      OrganizationsUser.make_user_admin(qa_cob_intake_clerk_user, ClerkOfTheBoard.singleton)
      BvaIntake.singleton.add_user(qa_cob_intake_clerk_user)
    end

    def create_qa_intake_clerk
      qa_intake_clerk = User.find_or_create_by(
        css_id: "QINTAKE",
        station_id: 101,
        full_name: "QA Intake Clerk",
        roles: ["Mail Intake"]
      )
      BvaIntake.singleton.add_user(qa_intake_clerk)
    end

    def create_qa_intake_admin
      qa_intake_admin_user = User.find_or_create_by(
        css_id: "QINTAKEADMIN",
        station_id: 101,
        full_name: "QA Intake Admin",
        roles: ["Mail Intake"]
      )
      OrganizationsUser.make_user_admin(qa_intake_admin_user, BvaIntake.singleton)
      OrganizationsUser.make_user_admin(qa_intake_admin_user, CDAControlGroup.singleton)
    end

    def create_qa_hearing_admin
      User.find_or_create_by(
        css_id: "QHEARADMIN",
        station_id: 343,
        full_name: "QA Hearings Admin",
        roles: ["Edit HearSched", "Build HearSched"]
      )
    end

    def create_qa_case_movement_user
      qa_case_movement_user = User.find_or_create_by(
        css_id: "QCASEMVMT",
        station_id: 101,
        full_name: "QA Case Movement"
      )
      FactoryBot.create(:staff, user: qa_case_movement_user)
      OrganizationsUser.make_user_admin(qa_case_movement_user, SpecialCaseMovementTeam.singleton)
    end

    def create_qa_attny_1
      User.find_or_create_by(
        css_id: "QATTY1",
        station_id: 101,
        full_name: "QA Attorney_1"
      )
    end

    def create_qa_attny_2
      User.find_or_create_by(
        css_id: "QATTY2",
        station_id: 101,
        full_name: "QA Attorney_2"
      )
    end

    def create_qa_attny_3
      User.find_or_create_by(
        css_id: "QATTY3",
        station_id: 101,
        full_name: "QA Attorney_3"
      )
    end

    def create_qa_judge_team_3
      qa_judge_3 = User.find_by(css_id: "QACTIVEVLJ3")
      qa_judge_team_3 = JudgeTeam.for_judge(qa_judge_3) || JudgeTeam.create_for_judge(qa_judge_3)
      qa_judge_team_3.add_user(User.find_by(css_id: "QATTY1"))
      qa_judge_team_3.add_user(User.find_by(css_id: "QATTY2"))
      qa_judge_team_3.add_user(User.find_by(css_id: "QATTY3"))
    end

    def create_qa_judge_team_2
      qa_judge_2 = User.find_by(css_id: "QACTIVEVLJ2")
      qa_judge_team_2 = JudgeTeam.for_judge(qa_judge_2) || JudgeTeam.create_for_judge(qa_judge_2)
      qa_judge_team_2.add_user(User.find_by(css_id: "QATTY1"))
      qa_judge_team_2.add_user(User.find_by(css_id: "QATTY2"))
    end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
