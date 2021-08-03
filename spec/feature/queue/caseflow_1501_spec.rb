# frozen_string_literal: true

def wait_for_page_render
  # This find forces a wait for the page to render. Without it, a test asserting presence or absence of content
  # may pass whether the content is present or not!
  find("div", id: "caseTitleDetailsSubheader")
end

RSpec.feature "CASEFLOW-1501 Substitute appellant behavior", :all_dbs do
  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
  end

  describe "Substitute Appellant appeal creation" do
    let(:cob_user) { create(:user, css_id: "COB_USER", station_id: "101") }

    before do
      sji = SanitizedJsonImporter.from_file(
        "db/seeds/sanitized_json/b5eba21a-9baf-41a3-ac1c-08470c2b79c4.json",
        verbosity: 0)
      sji.import

      FeatureToggle.enable!(:recognized_granted_substitution_after_dd)
      FeatureToggle.enable!(:hearings_substitution_death_dismissal)
      ClerkOfTheBoard.singleton.add_user(cob_user)
      OrganizationsUser.make_user_admin(cob_user, ClerkOfTheBoard.singleton)
      User.authenticate!(user: cob_user)
    end

    after do
      # This is probably not really needed, but let's be good stewards anyway:
      FeatureToggle.disable!(:recognized_granted_substitution_after_dd)
      FeatureToggle.disable!(:hearings_substitution_death_dismissal)
    end

    context "with just EvidenceOrArgumentMailTask selected" do
      let!(:appeal) { Appeal.find_by_uuid("b5eba21a-9baf-41a3-ac1c-08470c2b79c4") }

      before(:all) do
        #import_appeal_and_create_substitute

      end

      it "preserves the docker number" do
        appeal = Appeal.find_by_uuid("b5eba21a-9baf-41a3-ac1c-08470c2b79c4")
        puts appeal.inspect
        # You shouldn't have to visit /queue here, but if you hit the appeal directly right
        # off the bat it won't load. ¯\_(ツ)_/¯
        visit "/queue"
        visit "/queue/appeals/#{appeal.uuid}"
        wait_for_page_render
        # binding.pry
        # expect(page).to have_content(COPY::SUBSTITUTE_APPELLANT_BUTTON)

        click_on "+ Add Substitute"
        # wait_for_page_render
        # binding.pry
        fill_in("substitutionDate", with: "01/01/2021")
        find("label", text: "Bob Vance, Spouse").click
        click_on "Continue"

        # Woot, now we're at the task selection page!

        # Select "Evidence or argument" (2001578851 is the task ID)
        find("div", class: "checkbox-wrapper-taskIds[2001578851]").find("label").click
        click_on "Continue"
        click_on "Confirm"

        # Preserve the docket ID
        wait_for_page_render
        expect(page).to have_content(appeal.stream_docket_number)

        # TODO: Assert that AOD is preserved

        # Test the new appeal a bit:
        new_appeal = Appeal.find(1)
        puts new_appeal.treee

        # It creates the Distribution Task and EvidenceOrArgumentMailTask
        expect(DistributionTask.where(appeal_id: new_appeal.id).count).to eq(1)
        expect(DistributionTask.find_by(appeal_id: new_appeal.id).status).to eq("assigned")

        eamts = EvidenceOrArgumentMailTask.where(appeal_id: new_appeal.id)
        expect(eamts.count).to eq(3) # I mean this is kind of weird
        expect(eamts.map(&:status).uniq).to eq(%w(on_hold assigned))


      end

    end

  end
end