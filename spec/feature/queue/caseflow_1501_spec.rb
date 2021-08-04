# frozen_string_literal: true

def wait_for_page_render
  # This find forces a wait for the page to render. Without it, a test asserting presence or absence of content
  # may pass whether the content is present or not!
  find("div", id: "caseTitleDetailsSubheader")
end

# This is a gross workaround
def appeal
  return @appeal if @appeal
  SanitizedJsonImporter.from_file(
    "db/seeds/sanitized_json/b5eba21a-9baf-41a3-ac1c-08470c2b79c4.json",
    verbosity: 0).import
  @appeal = Appeal.find_by_uuid("b5eba21a-9baf-41a3-ac1c-08470c2b79c4")
end

#                                                         ┌────────────────────────────────────────────────────────────────────────────────────────┐
# Appeal 2000061110 (H 200103-61110 Original) ─────────── │ ID         │ STATUS    │ ASGN_BY      │ ASGN_TO            │ UPDATED_AT                │
# └── RootTask                                            │ 2000758351 │ completed │              │ Bva                │ 2021-02-04 07:12:27 -0500 │
#     ├── TrackVeteranTask                                │ 2000758352 │ completed │              │ PrivateBar         │ 2021-02-04 07:12:27 -0500 │
#     ├── DistributionTask                                │ 2000758353 │ completed │              │ Bva                │ 2021-02-01 07:09:14 -0500 │
#     │   ├── HearingTask                                 │ 2000758354 │ completed │              │ Bva                │ 2021-01-30 19:30:30 -0500 │
#     │   │   ├── ScheduleHearingTask                     │ 2000758355 │ completed │              │ Bva                │ 2020-10-01 12:01:04 -0400 │
#     │   │   │   └── HearingAdminActionVerifyAddressTask │ 2001143838 │ cancelled │              │ HearingsManagement │ 2020-09-16 20:36:59 -0400 │
#     │   │   └── AssignHearingDispositionTask            │ 2001178199 │ completed │              │ Bva                │ 2021-01-30 19:30:30 -0500 │
#     │   │       ├── TranscriptionTask                   │ 2001233993 │ completed │              │ TranscriptionTeam  │ 2020-12-22 09:20:00 -0500 │
#     │   │       └── EvidenceSubmissionWindowTask        │ 2001233994 │ completed │              │ MailTeam           │ 2021-01-30 19:30:30 -0500 │
#     │   │           └── EvidenceSubmissionWindowTask    │ 2001255555 │ cancelled │ MBUTLERBVAI  │ BAKERBVAW          │ 2020-11-17 11:31:25 -0500 │
#     │   ├── HearingRelatedMailTask                      │ 2000786274 │ completed │              │ MailTeam           │ 2020-07-08 10:34:32 -0400 │
#     │   │   └── HearingRelatedMailTask                  │ 2000786275 │ completed │ MCWILJVACO   │ HearingAdmin       │ 2020-07-08 10:34:32 -0400 │
#     │   └── HearingRelatedMailTask                      │ 2001298868 │ completed │              │ MailTeam           │ 2020-12-10 09:58:33 -0500 │
#     │       └── HearingRelatedMailTask                  │ 2001298869 │ completed │ MURRELLBVAC  │ HearingAdmin       │ 2020-12-10 09:58:33 -0500 │
#     ├── JudgeAssignTask                                 │ 2001429904 │ completed │              │ ELEZEBVAV          │ 2021-02-01 08:17:22 -0500 │
#     ├── JudgeDecisionReviewTask                         │ 2001430264 │ completed │ HSMITHBVAT   │ ELEZEBVAV          │ 2021-02-02 12:59:59 -0500 │
#     │   └── AttorneyTask                                │ 2001430265 │ completed │ ELEZEBVAV    │ HSMITHBVAT         │ 2021-02-02 09:58:20 -0500 │
#     ├── BvaDispatchTask                                 │ 2001435755 │ completed │              │ BvaDispatch        │ 2021-02-04 07:12:26 -0500 │
#     │   └── BvaDispatchTask                             │ 2001435756 │ completed │              │ MILLEK2VACO        │ 2021-02-04 07:12:26 -0500 │
#     ├── EvidenceOrArgumentMailTask                      │ 2001578850 │ completed │              │ MailTeam           │ 2021-03-24 13:15:02 -0400 │
#     │   └── EvidenceOrArgumentMailTask                  │ 2001578851 │ completed │ CULVEDVACO   │ Colocated          │ 2021-03-24 13:15:02 -0400 │
#     │       ├── EvidenceOrArgumentMailTask              │ 2001578852 │ cancelled │ CULVEDVACO   │ WIGGIGVACO         │ 2021-03-24 13:07:44 -0400 │
#     │       └── EvidenceOrArgumentMailTask              │ 2001580304 │ completed │ BOOKEKVACO   │ BOOKEKVACO         │ 2021-03-24 13:15:02 -0400 │
#     └── EvidenceOrArgumentMailTask                      │ 2001805324 │ on_hold   │              │ MailTeam           │ 2021-06-28 12:38:07 -0400 │
#         └── EvidenceOrArgumentMailTask                  │ 2001805325 │ on_hold   │ BARNAMCL     │ Colocated          │ 2021-06-28 12:38:07 -0400 │
#             └── EvidenceOrArgumentMailTask              │ 2001805326 │ on_hold   │ BARNAMCL     │ DJOHNSONBVAA       │ 2021-06-28 13:40:57 -0400 │
#                 └── EvidenceOrArgumentMailTask          │ 2001805531 │ on_hold   │ DJOHNSONBVAA │ PrivacyTeam        │ 2021-07-01 19:49:48 -0400 │
#                     └── EvidenceOrArgumentMailTask      │ 2001816737 │ assigned  │ RETANBVAJ    │ TranscriptionTeam  │ 2021-07-01 19:49:48 -0400 │
#                                                         └────────────────────────────────────────────────────────────────────────────────────────┘

RSpec.feature "CASEFLOW-1501 Substitute appellant behavior", :all_dbs do
  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
  end

  describe "Substitute Appellant appeal creation" do
    after do
      # This is probably not really needed, but let's be good stewards anyway:
      FeatureToggle.disable!(:recognized_granted_substitution_after_dd)
      FeatureToggle.disable!(:hearings_substitution_death_dismissal)
    end

    # I had to cram all this in one go or nothing worked right.
    # This is still fairly gross.
    before(:all) do
      FeatureToggle.enable!(:recognized_granted_substitution_after_dd)
      FeatureToggle.enable!(:hearings_substitution_death_dismissal)

      cob_user = create(:user, css_id: "COB_USER", station_id: "101")
      ClerkOfTheBoard.singleton.add_user(cob_user)
      OrganizationsUser.make_user_admin(cob_user, ClerkOfTheBoard.singleton)
      User.authenticate!(user: cob_user)

      #puts appeal.treee

      # You shouldn't have to visit /queue here, but if you hit the appeal directly right
      # off the bat it won't load. ¯\_(ツ)_/¯
      visit "/queue"
      visit "/queue/appeals/#{appeal.uuid}"
      wait_for_page_render
      # binding.pry

      click_on "+ Add Substitute"

      fill_in("substitutionDate", with: "01/01/2021")
      find("label", text: "Bob Vance, Spouse").click
      click_on "Continue"

      # Select "Evidence or argument" (2001578851 is the task ID)
      find("div", class: "checkbox-wrapper-taskIds[2001578851]").find("label").click
      click_on "Continue"
      click_on "Confirm"
      wait_for_page_render
    end

    context "with just EvidenceOrArgumentMailTask selected" do
      #let!(:appeal) { Appeal.find_by_uuid("b5eba21a-9baf-41a3-ac1c-08470c2b79c4") }

      it "preserves the docket number" do
        expect(page).to have_content(appeal.stream_docket_number)
      end

      it "preserves AOD" do
        # TODO
        # I'm not sure it would, since it's partly based on the veteran
      end

      it "preserves appeal status" do
        # TODO
      end

      it "tries with different types of selected tasks" do
        # TODO
        # This is (important) complexity for tomorrow.
      end

      it "creates the selected tasks" do
        new_appeal = Appeal.find(1)
        # puts new_appeal.treee

        # It creates the Distribution Task and EvidenceOrArgumentMailTask
        expect(DistributionTask.where(appeal_id: new_appeal.id).count).to eq(1)
        expect(DistributionTask.find_by(appeal_id: new_appeal.id).status).to eq("assigned")

        eamts = EvidenceOrArgumentMailTask.where(appeal_id: new_appeal.id)
        expect(eamts.count).to eq(3) # I mean this is kind of weird
        expect(eamts.map(&:status).uniq.sort).to eq(%w(assigned on_hold))
      end

      it "all typical parent tasks are created or are in existence for the user-selected task" do
        # TODO
      end

      it "verify tasks from source appeal are displayed in the case timeline" do
        # TODO
      end

      it "the granted substitution date is added to the about the appellant section" do
        # TODO
      end

      it "shows a success banner" do
        expect(page).to have_content("You have successfully added a substitute appellant")
      end

    end

  end
end