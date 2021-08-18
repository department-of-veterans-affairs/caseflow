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
      "BVAAWAKEFIELD" => { attorneys: %w[BVAABELANGER] }
    }.freeze

    DEVELOPMENT_DVC_TEAMS = {
      "BVATCOLLIER" => %w[BVAAABSHIRE BVAGSPORER BVAEBECKER]
    }.freeze

    def seed!
      create_users
    end

    private

    def create_users
      User.create(css_id: "BVASCASPER1", station_id: 101, full_name: "Steve Attorney_Cases Casper")
      User.create(css_id: "BVASRITCHIE", station_id: 101, full_name: "Sharree AttorneyNoCases Ritchie")
      User.create(css_id: "BVAAABSHIRE", station_id: 101, full_name: "Aaron Judge_HearingsAndCases Abshire")
      User.create(css_id: "BVARERDMAN", station_id: 101, full_name: "Rachael JudgeHasAttorneys_Cases Erdman")
      User.create(css_id: "BVAEBECKER", station_id: 101, full_name: "Elizabeth Judge_CaseToAssign Becker")
      User.create(css_id: "BVAKKEELING", station_id: 101, full_name: "Keith Judge_CaseToAssign_NoTeam Keeling")
      User.create(css_id: "BVAAWAKEFIELD", station_id: 101, full_name: "Apurva Judge_CaseAtDispatch Wakefield")
      User.create(css_id: "BVAABELANGER", station_id: 101, full_name: "Andy Attorney_CaseAtDispatch Belanger")
      User.create(css_id: "BVATWARNER", station_id: 101, full_name: "Theresa BuildHearingSchedule Warner")
      User.create(css_id: "BVAGWHITE", station_id: 101, full_name: "George BVADispatchUser_Cases White")
      User.create(css_id: "BVAGGREY", station_id: 101, full_name: "Gina BVADispatchUser_NoCases Grey")
      User.create(css_id: "BVATCOLLIER", station_id: 101, full_name: "Tonja DVCTeam Collier")
      dispatch_admin = User.create(
        css_id: "BVAGBLACK",
        station_id: 101,
        full_name: "Geoffrey BVADispatchAdmin_NoCases Black"
      )
      OrganizationsUser.make_user_admin(dispatch_admin, BvaDispatch.singleton)
      case_review_admin = User.create(css_id: "BVAKBLUE", station_id: 101, full_name: "Kim CaseReviewAdmin Blue")
      OrganizationsUser.make_user_admin(case_review_admin, CaseReview.singleton)
      special_case_movement_user = User.create(css_id: "BVARDUNKLE",
                                               station_id: 101,
                                               full_name: "Rosalie SpecialCaseMovement Dunkle")
      FactoryBot.create(:staff, user: special_case_movement_user)
      SpecialCaseMovementTeam.singleton.add_user(special_case_movement_user)
      special_case_movement_admin = User.create(css_id: "BVAGBEEKMAN",
                                                station_id: 101,
                                                full_name: "Bryan SpecialCaseMovementAdmin Beekman")
      FactoryBot.create(:staff, user: special_case_movement_admin)
      OrganizationsUser.make_user_admin(special_case_movement_admin, SpecialCaseMovementTeam.singleton)
      bva_intake_admin = User.create(css_id: "BVADWISE", station_id: 101, full_name: "Deborah BvaIntakeAdmin Wise")
      OrganizationsUser.make_user_admin(bva_intake_admin, BvaIntake.singleton)
      bva_intake_user = User.create(css_id: "BVAISHAW", station_id: 101, full_name: "Ignacio BvaIntakeUser Shaw")
      BvaIntake.singleton.add_user(bva_intake_user)

      Functions.grant!("System Admin", users: User.all.pluck(:css_id))

      create_team_admin
      create_colocated_users
      create_transcription_team
      create_vso_users_and_tasks
      create_field_vso_and_users
      create_pva_vso_and_users
      create_org_queue_users
      create_visn_org_queues
      create_qr_user
      create_aod_user_and_tasks
      create_privacy_user
      create_lit_support_user
      create_cavc_lit_support_user
      create_pulac_cerullo_user
      create_mail_team_user
      create_clerk_of_the_board_users
      create_case_search_only_user
      create_judge_teams
      create_dvc_teams
      create_hearings_user
      create_build_and_edit_hearings_users
      create_non_admin_hearing_coordinator_user
    end

    def create_team_admin
      u = User.create(css_id: "TEAM_ADMIN", station_id: 101, full_name: "Jim TeamAdminSystemAdmin Jones")
      existing_sysadmins = Functions.details_for("System Admin")[:granted] || []
      Functions.grant!("System Admin", users: existing_sysadmins + [u.css_id])
      Bva.singleton.add_user(u)
    end

    def create_colocated_users
      secondary_user = create(:user, full_name: "Harper SecondaryVLJSupportStaff Tash", roles: %w[Reader])
      create(:staff, :colocated_role, user: secondary_user, sdept: "DSP")
      Colocated.singleton.add_user(secondary_user)

      user = User.create(
        css_id: "BVALSPORER",
        station_id: 101,
        full_name: "Laura Co-located_Cases Sporer",
        roles: %w[Reader]
      )
      create(:staff, :colocated_role, user: user, sdept: "DSP")
      Colocated.singleton.add_user(user)

      admin = User.create(
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

      %w[BILLIE MICHAEL].each do |name|
        u = User.create(
          css_id: "#{name}_VSO",
          station_id: 101,
          full_name: "#{name} VSOUser Jones",
          roles: %w[VSO]
        )
        vso.add_user(u)

        # Assign one IHP task to each member of the VSO team and leave some IHP tasks assigned to the organization.
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
        user = User.create(**params)
        HearingsManagement.singleton.add_user(user)
        HearingAdmin.singleton.add_user(user)
      end
    end

    def create_non_admin_hearing_coordinator_user
      hearings_user = User.create(
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
        u = User.create(
          css_id: "#{name}_PVA_VSO",
          station_id: 101,
          full_name: "#{name} PVA_VSOUser James",
          roles: %w[VSO]
        )
        vso.add_user(u)
      end
    end

    def create_field_vso_and_users
      vso = create(:field_vso, name: "Field VSO", url: "field-vso")

      %w[MANDY NICHOLAS ELIJAH].each do |name|
        u = User.create(
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
      nca = BusinessLine.create!(name: "National Cemetery Administration", url: "nca")
      %w[Parveen Chandra Sydney Tai Kennedy].each do |name|
        u = User.create!(station_id: 101, css_id: "NCA_QUEUE_USER_#{name}", full_name: "#{name} NCAUser Carter")
        nca.add_user(u)
      end

      %w[Kun Casey Ariel Naomi Kelly].each do |name|
        u = User.create!(station_id: 101, css_id: "ORG_QUEUE_USER_#{name}", full_name: "#{name} TranslationUser Cullen")
        Translation.singleton.add_user(u)
      end
    end

    def visn_orgs
      [
        {
          name: "VA New England Healthcare System",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "New York/New Jersey VA Health Care Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Healthcare",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Capitol Health Care Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Mid-Atlantic Health Care Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Southeast Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Sunshine Healthcare Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA MidSouth Healthcare Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Healthcare System",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Great Lakes Health Care System",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Heartland Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "South Central VA Health Care Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Heart of Texas Health Care Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "Rocky Mountain Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "Northwest Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "Sierra Pacific Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "Desert Pacific Healthcare Network",
          url: "",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Midwest Health Care Network",
          url: "",
          type: "VhaRegionalOffice"
        }
      ]
    end

    def create_visn_org_queues
      visn_orgs.each do |org|
        visn = VhaRegionalOffice.create!(org)
      end
    end

    def create_qr_user
      qr_user = User.create!(station_id: 101, css_id: "QR_USER", full_name: "Yarden QualityReviewer Jordan")
      QualityReview.singleton.add_user(qr_user)
    end

    def create_aod_user_and_tasks
      u = User.create!(station_id: 101, css_id: "AOD_USER", full_name: "Shiloh AODUser Villar")
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
      u = User.create!(station_id: 101, css_id: "PRIVACY_TEAM_USER", full_name: "Leighton PrivacyAndFOIAUser Naumov")
      PrivacyTeam.singleton.add_user(u)
    end

    def create_lit_support_user
      u = User.create!(station_id: 101, css_id: "LIT_SUPPORT_USER", full_name: "Kiran LitigationSupportUser Rider")
      LitigationSupport.singleton.add_user(u)
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
        User.create!(station_id: 101,
                     css_id: user_info[:css_id],
                     full_name: user_info[:full_name])
      end

      users.each { |u| CavcLitigationSupport.singleton.add_user(u) }
      OrganizationsUser.make_user_admin(users.first, CavcLitigationSupport.singleton)
      OrganizationsUser.make_user_admin(users.second, CavcLitigationSupport.singleton)
    end

    def create_pulac_cerullo_user
      u = User.create!(station_id: 101, css_id: "BVAKSOSNA", full_name: "KATHLEEN PulacCerulloUser SOSNA")
      PulacCerullo.singleton.add_user(u)
    end

    def create_mail_team_user
      u = User.create!(station_id: 101, css_id: "JOLLY_POSTMAN", full_name: "Huan MailUser Tiryaki")
      MailTeam.singleton.add_user(u)
    end

    def create_clerk_of_the_board_users
      atty = create(
        :user,
        :with_vacols_attorney_record,
        station_id: 101,
        css_id: "COB_USER",
        full_name: "Clark ClerkOfTheBoardUser Bard"
      )
      ClerkOfTheBoard.singleton.add_user(atty)

      judge = create(:user, full_name: "Judith COTB Judge", css_id: "BVACOTBJUDGE")
      create(:staff, :judge_role, sdomainid: judge.css_id)
      ClerkOfTheBoard.singleton.add_user(judge)

      admin = create(:user, full_name: "Ty ClerkOfTheBoardAdmin Cobb", css_id: "BVATCOBB")
      ClerkOfTheBoard.singleton.add_user(admin)
      OrganizationsUser.make_user_admin(admin, ClerkOfTheBoard.singleton)
    end

    def create_case_search_only_user
      User.create!(station_id: 101, css_id: "CASE_SEARCHER_ONLY", full_name: "Blair CaseSearchAccessNoQueueAccess Lyon")
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
