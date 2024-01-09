# frozen_string_literal: true

def wait_for_page_render
  # This find forces a wait for the page to render. Without it, a test asserting presence or absence of content
  # may pass whether the content is present or not!
  find("div", id: "caseTitleDetailsSubheader")
end

RSpec.feature "Case details", :all_dbs do
  let!(:frontend_time) { Time.zone.now } # The frontend does not abide by Timecop's time
  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
  end

  let(:attorney_first_name) { "Chanel" }
  let(:attorney_last_name) { "Afshari" }
  let!(:attorney_user) do
    create(:user, full_name: "#{attorney_first_name} #{attorney_last_name}")
  end
  let!(:vacols_atty) do
    create(
      :staff,
      :attorney_role,
      sdomainid: attorney_user.css_id,
      snamef: attorney_first_name,
      snamel: attorney_last_name
    )
  end

  let(:judge_first_name) { "Eeva" }
  let(:judge_last_name) { "Jovich" }
  let!(:judge_user) { create(:user, full_name: "#{judge_first_name} #{judge_last_name}") }
  let!(:vacols_judge) do
    create(
      :staff,
      :judge_role,
      sdomainid: judge_user.css_id,
      snamef: judge_first_name,
      snamel: judge_last_name
    )
  end

  let(:colocated_user) { create(:user) }
  let!(:vacols_colocated) { create(:staff, :colocated_role, sdomainid: colocated_user.css_id) }

  before do
    User.authenticate!(user: attorney_user)
  end

  context "hearings panel on attorney task detail view" do
    let(:veteran_first_name) { "Linda" }
    let(:veteran_last_name) { "Verne" }
    let!(:veteran) do
      create(
        :veteran,
        first_name: veteran_first_name,
        last_name: veteran_last_name,
        file_number: 123_456_789
      )
    end
    let!(:post_remanded_appeal) do
      create(
        :legacy_appeal,
        vacols_case: create(
          :case,
          :assigned,
          :type_post_remand,
          bfcorlid: veteran.file_number,
          user: attorney_user
        )
      )
    end
    let!(:appeal) do
      create(
        :legacy_appeal,
        vacols_case: create(
          :case,
          :assigned,
          user: attorney_user,
          bfcorlid: veteran.file_number,
          # Need a non-cancelled disposition to show the full set of hearing attributes.
          case_hearings: case_hearings
        )
      )
    end
    let(:hearing) { appeal.hearings.first }

    context "when appeal has a single hearing that has already been held" do
      let!(:case_hearings) { [build(:case_hearing, :disposition_held, user: judge_user)] }

      scenario "Entire set of attributes for hearing are displayed" do
        visit "/queue"

        find_table_cell(appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link

        expect(page).to have_content("Select an action")
        expect(page).to have_content(COPY::CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY)
        expect(page).to have_content("Type: #{hearing.readable_request_type}")
        expect(page).to have_content("Date: #{hearing.scheduled_for.strftime('%-m/%-d/%y')}")
        expect(page).to have_content("Judge: #{hearing.user.full_name}")
      end

      scenario "post remanded appeal shows indication of earlier appeal hearing" do
        visit "/queue"

        find_table_cell(post_remanded_appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link

        expect(page).to have_content("Select an action")
        expect(page).to have_content(COPY::CASE_DETAILS_HEARING_ON_OTHER_APPEAL)
      end
    end

    context "when appeal has a single hearing that was cancelled" do
      let!(:case_hearings) { [build(:case_hearing, :disposition_cancelled, user: judge_user)] }

      scenario "Fewer attributes of hearing are displayed" do
        visit "/queue"

        find_table_cell(appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link

        hearing = appeal.hearings.first
        expect(page).to have_content("Type: #{hearing.readable_request_type}")

        expect(page).to have_content("Disposition: #{Constants.HEARING_DISPOSITION_TYPE_TO_LABEL_MAP.cancelled}")
        expect(page).to have_content("Date: ")
        expect(page).to have_content("Judge: ")
      end
    end

    context "when appeal has a single hearing with a HearingView" do
      let!(:case_hearings) { [build(:case_hearing, :disposition_held, user: judge_user)] }
      before { HearingView.create(hearing: hearing, user_id: attorney_user.id).touch }

      scenario "Fewer attributes of hearing are displayed" do
        visit "/queue"
        find_table_cell(appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link

        expect(page).to have_current_path("/queue/appeals/#{appeal.vacols_id}")

        expect(page).to have_selector(".cf-hearing-badge")

        scroll_to("#hearings-section")
        worksheet_link = page.find(
          "a[href='/hearings/worksheet/print?keep_open=true&hearing_ids=#{hearing.external_id}']"
        )
        expect(worksheet_link.text).to eq(COPY::CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY)

        details_link = page.find("a[href='/hearings/#{hearing.external_id}/details']")
        expect(details_link.text).to eq(COPY::CASE_DETAILS_HEARING_DETAILS_LINK_COPY)
      end

      context "the user has a VSO role" do
        let!(:vso) { create(:vso, name: "VSO", role: "VSO", url: "vso-url", participant_id: "8054") }
        let!(:vso_user) { create(:user, :vso_role) }
        let!(:vso_task) { create(:ama_vso_task, :in_progress, assigned_to: vso, appeal: appeal) }

        before do
          vso.add_user(vso_user)
          allow_any_instance_of(Representative).to receive(:user_has_access?).and_return(true)
          User.authenticate!(user: vso_user)
        end

        scenario "worksheet and details links are not visible" do
          visit vso.path
          click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
          expect(page).to have_current_path("/queue/appeals/#{appeal.vacols_id}")
          scroll_to("#hearings-section")
          expect(page).to_not have_content(COPY::CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY)
          expect(page).to_not(
            have_css("a[href='/hearings/worksheet/print?keep_open=true&hearing_ids=#{hearing.external_id}']")
          )
          expect(page).to_not have_content(COPY::CASE_DETAILS_HEARING_DETAILS_LINK_COPY)
          expect(page).to_not have_css("a[href='/hearings/#{hearing.external_id}/details']")
        end
      end
    end

    context "when appeal has no associated hearings" do
      let!(:case_hearings) { [] }

      scenario "Hearings info box is not displayed" do
        visit "/queue"
        find_table_cell(appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link
        expect(page.has_no_content?("Hearing preference")).to eq(true)
      end
    end
  end

  context "attorney case details view" do
    context "when Veteran is the appellant" do
      let(:veteran) { create(:veteran, sex: "F") }
      let!(:appeal) do
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(
            :case,
            :assigned,
            user: attorney_user,
            bfcorlid: veteran.file_number
          )
        )
      end

      scenario "details view informs us that the Veteran is the appellant" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

        expect(page).to have_content("About the Veteran")
        expect(page.has_no_content?("About the Appellant")).to eq(true)
        expect(page).to have_content(COPY::CASE_DETAILS_GENDER_FIELD_VALUE_FEMALE)
        expect(page).to have_content("1/1/1990")
        expect(page).to have_content(appeal.veteran_address_line_1)
        expect(page).to_not have_content("Regional Office")
      end

      context "when there is no POA" do
        before do
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poa_by_file_number).and_return(nil)
          allow(BgsPowerOfAttorney).to receive(:fetch_bgs_poa_by_participant_id).and_return(nil)
        end

        scenario "contains message for no POA" do
          visit "/queue"
          click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
          expect(page).to have_content("Power of Attorney")
          expect(page).to have_content(COPY::CASE_DETAILS_NO_POA)
        end
      end
    end

    context "when veteran is not in BGS" do
      let(:veteran) { create(:veteran, sex: "F") }
      let!(:appeal) do
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(
            :case,
            :assigned,
            user: attorney_user,
            bfcorlid: veteran.file_number
          )
        )
      end

      before do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_return(nil)
      end

      scenario "details view informs us that the Veteran is the appellant" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

        expect(page).to have_content("About the Veteran")
        expect(page.has_no_content?("About the Appellant")).to eq(true)
        expect(page).to_not have_content("1/1/1990")
        expect(page).to_not have_content("5/25/2016")
        expect(page).to_not have_content("Regional Office")

        # Veteran gender information comes from BGS so case details page will display no gender information when the
        # Veteran is not in BGS.
        expect(page).to_not have_content(COPY::CASE_DETAILS_GENDER_FIELD_VALUE_FEMALE)
        expect(page).to_not have_content(COPY::CASE_DETAILS_GENDER_FIELD_VALUE_MALE)
      end
    end

    context "when veteran is in BGS" do
      let!(:appeal) do
        create(
          :appeal
        )
      end
      scenario "details view informs us that the Veteran data source is BGS" do
        visit("/queue/appeals/#{appeal.external_id}")
        expect(page).to have_content("About the Veteran")
        expect(page).to have_content(COPY::CASE_DETAILS_VETERAN_ADDRESS_SOURCE)
        expect(page).to_not have_content("Regional Office")
      end
    end

    context "when Veteran is not the appellant" do
      let!(:appeal) do
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(
            :case,
            :assigned,
            user: attorney_user,
            correspondent: create(
              :correspondent,
              appellant_first_name: "Not",
              appellant_middle_initial: "D",
              appellant_last_name: "Veteran"
            )
          )
        )
      end

      scenario "details view informs us that the Veteran is not the appellant" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

        expect(page).to have_content("About the Appellant")
        expect(page).to have_content("About the Veteran")
        expect(page).to have_content(appeal.veteran_address_line_1)
        expect(page).to have_content(appeal.appellant_name)
        expect(page).to have_content(appeal.appellant_relationship)
        expect(page).to have_content(appeal.appellant_address_line_1)
        expect(page).to have_content(COPY::CASE_DETAILS_VETERAN_ADDRESS_SOURCE)
        expect(page).to have_content(COPY::CASE_DETAILS_POA_EXPLAINER)
        expect(page).to have_content(appeal.power_of_attorney.bgs_representative_name)
        expect(page).to_not have_content("Regional Office")
      end

      context "when there is no POA" do
        before do
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poa_by_file_number).and_return(nil)
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids).and_return(nil)
        end

        scenario "contains message for no POA" do
          visit "/queue"
          click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
          expect(page).to have_content("Appellant's Power of Attorney")
          expect(page).to have_content(COPY::CASE_DETAILS_NO_POA)
        end
      end
    end

    context "when appellant is an attorney or unlisted claimant" do
      let(:bgs_atty) { create(:bgs_attorney) }
      let(:appeal) do
        create(
          :appeal,
          associated_judge: judge_user,
          associated_attorney: attorney_user,
          number_of_claimants: 0,
          veteran_is_not_claimant: true
        )
      end

      %w[Attorney Other].each do |claimant_type|
        scenario "details view informs us that appellant's relationship to Veteran is #{claimant_type}" do
          claimant = create(
            :claimant,
            :with_unrecognized_appellant_detail,
            decision_review: appeal,
            type: "#{claimant_type}Claimant",
            participant_id: bgs_atty.participant_id,
            notes: (claimant_type == "Other") ? "sample notes" : nil
          )
          visit "/queue/appeals/#{appeal.uuid}"

          expect(page).to have_content("About the Veteran")
          expect(page).to have_content("About the Appellant")
          expect(page).to have_content("Relation to Veteran: #{claimant.relationship}")
        end
      end

      context "when an unrecognized appellant has an unrecognized POA" do
        before do
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poa_by_file_number).and_return(nil)

          allow_any_instance_of(BgsPowerOfAttorney).to receive(:representative_type)
            .and_return("Unrecognized representative")

          allow(BgsPowerOfAttorney).to receive(:fetch_bgs_poa_by_participant_id).and_return(nil)
          allow(BgsPowerOfAttorney).to receive(:find_or_create_by_claimant_participant_id).and_return(nil)
          FeatureToggle.enable!(:poa_button_refresh)
        end
        after { FeatureToggle.disable!(:poa_button_refresh) }

        let!(:claimant) do
          create(
            :claimant,
            unrecognized_appellant: ua,
            decision_review: appeal,
            type: "OtherClaimant"
          )
        end

        let(:ua) { create(:unrecognized_appellant) }

        scenario "details view renders unrecognized POA copy" do
          visit "/queue/appeals/#{appeal.uuid}"
          expect(page).to have_content(COPY::CASE_DETAILS_UNRECOGNIZED_POA)
          expect(page).to_not have_button("Refresh POA")
        end
      end

      context "when an unrecognized appellant has a recognized POA" do
        before do
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids).and_return(true)
          FeatureToggle.enable!(:poa_button_refresh)
        end
        after { FeatureToggle.disable!(:poa_button_refresh) }

        let!(:claimant) do
          create(
            :claimant,
            unrecognized_appellant: ua,
            decision_review: appeal,
            type: "OtherClaimant"
          )
        end

        let(:ua) { create(:unrecognized_appellant) }

        scenario "details view contains POA information" do
          visit "/queue/appeals/#{appeal.uuid}"
          expect(page).to have_content(COPY::CASE_DETAILS_UNRECOGNIZED_POA)
          expect(page).to have_content(appeal.representative_name)
          expect(page).to_not have_button("Refresh POA")
        end
      end

      context "when a recognized appellant has a recognized POA" do
        let(:regional_office_key) { "RO17" }
        let(:appeal) do
          create(
            :appeal,
            closest_regional_office: regional_office_key
          )
        end
        let!(:poa) do
          create(
            :bgs_power_of_attorney,
            :with_name_cached,
            appeal: appeal,
            claimant_participant_id: appeal.claimant.participant_id
          )
        end
        before do
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids).and_return(true)
          FeatureToggle.enable!(:poa_button_refresh)
        end
        after { FeatureToggle.disable!(:poa_button_refresh) }

        scenario "details view contains POA information and displays POA Refresh Btn" do
          visit "/queue/appeals/#{appeal.uuid}"
          expect(page).to have_content(appeal.representative_name)
          expect(page).to have_button("Refresh POA")
        end
      end
    end

    context "when attorney has a case assigned in VACOLS without a DECASS record" do
      let!(:appeal) do
        create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :assigned,
            decass_count: 0,
            user: attorney_user
          )
        )
      end

      it "should not display a tasks action dropdown" do
        visit("/queue/appeals/#{appeal.external_id}")

        # Expect to find content we know to be on the page so that we wait for the page to load.
        expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
        expect(page.has_no_content?("Select an action")).to eq(true)
      end
    end

    context "POA refresh text isn't shown without feature toggle enabled" do
      let!(:user) { User.authenticate!(roles: ["System Admin"]) }
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "0000000000S")) }
      let!(:veteran) { create(:veteran, file_number: appeal.sanitized_vbms_id) }

      before { FeatureToggle.disable!(:poa_button_refresh) }

      scenario "text isn't on the page" do
        visit "/queue/appeals/#{appeal.vacols_id}"
        expect(page.has_no_content?(COPY::CASE_DETAILS_POA_LAST_SYNC_DATE_COPY)).to eq(true)
      end
    end

    context "POA refresh text is shown with feature toggle enabled" do
      let!(:user) { User.authenticate!(roles: ["System Admin"]) }
      let(:appeal) { create(:appeal, veteran: create(:veteran)) }
      let!(:poa) do
        create(
          :bgs_power_of_attorney,
          :with_name_cached,
          appeal: appeal
        )
      end

      before { FeatureToggle.enable!(:poa_button_refresh) }
      after { FeatureToggle.disable!(:poa_button_refresh) }

      scenario "text is on the page" do
        poa.save!
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content("POA last refreshed on")
      end
    end

    context "POA refresh text isn't shown when no POA is found" do
      let!(:user) { User.authenticate!(roles: ["System Admin"]) }
      let(:appeal) { create(:appeal, veteran: create(:veteran)) }

      before { FeatureToggle.enable!(:poa_button_refresh) }
      after { FeatureToggle.disable!(:poa_button_refresh) }

      scenario "text is not on the page" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page.has_no_content?(COPY::CASE_DETAILS_POA_LAST_SYNC_DATE_COPY)).to eq(true)
      end
    end

    context "POA refresh button isn't shown without feature toggle enabled" do
      let!(:user) { User.authenticate!(roles: ["System Admin"]) }
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "0000000000S")) }
      let!(:veteran) { create(:veteran, file_number: appeal.sanitized_vbms_id) }

      before do
        FeatureToggle.disable!(:poa_button_refresh)
      end
      after do
        FeatureToggle.enable!(:poa_button_refresh)
      end

      scenario "button isn't on the page" do
        visit "/queue/appeals/#{appeal.vacols_id}"
        expect(page.has_no_content?("Refresh POA")).to eq(true)
      end
    end

    context "POA refresh button is shown with feature toggle enabled" do
      before { FeatureToggle.enable!(:poa_button_refresh) }
      after { FeatureToggle.disable!(:poa_button_refresh) }

      let(:veteran) { create(:veteran) }
      let(:claimant_participant_id) { "2019111203" }
      let(:claimant) { create(:claimant, participant_id: claimant_participant_id) }
      let!(:appeal) do
        create(:appeal, claimants: [claimant], veteran_file_number: veteran.file_number)
      end
      let!(:poa) do
        create(
          :bgs_power_of_attorney,
          :with_name_cached,
          appeal: appeal
        )
      end

      scenario "button is on the page and is in cooldown" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content("Refresh POA")
        click_on "Refresh POA"
        expect(page).to have_content("Information is current at this time. Please try again in 10 minutes")
        expect(page).to have_content("POA last refreshed on 01/01/2020")
      end

      scenario "button is on the page and updates" do
        allow_any_instance_of(AppealsController).to receive(:cooldown_period_remaining).and_return(0)
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content("Refresh POA")
        click_on "Refresh POA"
        expect(page).to have_content(COPY::POA_UPDATED_SUCCESSFULLY)
        expect(page).to have_content("POA last refreshed on 01/01/2020")
      end

      context "when there is not currently a POA in BGS" do
        before do
          Rails.cache.write("bgs-participant-poa-not-found-#{appeal.veteran.file_number}", true)
          Rails.cache.write("bgs-participant-poa-not-found-#{appeal.claimant.participant_id}", true)
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids).and_return({})
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poa_by_file_number).and_return({})
          BgsPowerOfAttorney.skip_callback(:save, :before, :update_cached_attributes!)
        end
        after { BgsPowerOfAttorney.set_callback(:save, :before, :update_cached_attributes!) }

        context "when the appeal previously did not have a POA" do
          let!(:poa) { nil }

          scenario "Request succeeds and shows not found message" do
            visit "/queue/appeals/#{appeal.uuid}"

            expect(appeal.power_of_attorney).to eq(nil)
            expect(Rails.cache.read("bgs-participant-poa-not-found-#{appeal.claimant.participant_id}")).to eq(true)
            expect(Rails.cache.read("bgs-participant-poa-not-found-#{appeal.veteran.file_number}")).to eq(true)
            expect(page).to have_content("Refresh POA")

            click_on "Refresh POA"

            expect(page).to have_content("Successfully refreshed. No power of attorney information was found")
            expect(page).to have_content("POA last refreshed on")
            expect(appeal.power_of_attorney).to eq(nil)
            expect(Rails.cache.read("bgs-participant-poa-not-found-#{appeal.claimant.participant_id}")).to eq(true)
            expect(Rails.cache.read("bgs-participant-poa-not-found-#{appeal.veteran.file_number}")).to eq(true)
          end
        end

        context "when the appeal previously had a POA" do
          let!(:claimant_poa) do
            create(
              :bgs_power_of_attorney,
              claimant_participant_id: claimant_participant_id,
              last_synced_at: Time.zone.now - 5.years
            )
          end

          scenario "shows that there is no POA after update" do
            visit "/queue/appeals/#{appeal.uuid}"

            expect(appeal.claimant.power_of_attorney).to_not eq(nil)
            expect(appeal.power_of_attorney).to_not eq(nil)
            expect(Rails.cache.read("bgs-participant-poa-not-found-#{appeal.claimant.participant_id}")).to eq(true)
            expect(Rails.cache.read("bgs-participant-poa-not-found-#{appeal.veteran.file_number}")).to eq(true)
            expect(page).to have_content("VSO: POA Name")
            expect(page).to have_content("POA last refreshed on #{claimant_poa.last_synced_at.mdY}")
            expect(page).to have_content("Refresh POA")

            click_on "Refresh POA"

            expect(page).to have_content("Successfully refreshed. No power of attorney information was found")
            expect(page).to have_content("POA last refreshed on")
            expect(appeal.claimant.power_of_attorney).to eq(nil)
            expect(appeal.power_of_attorney).to eq(nil)
            expect(Rails.cache.read("bgs-participant-poa-not-found-#{appeal.claimant.participant_id}")).to eq(true)
            expect(Rails.cache.read("bgs-participant-poa-not-found-#{appeal.veteran.file_number}")).to eq(true)
          end
        end
      end
    end

    context "veteran records have been merged and Veteran has multiple active phone numbers in SHARE",
            skip: "This test fails in GHA but not locally" do
      let!(:appeal) do
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(
            :case,
            :assigned,
            user: attorney_user
          )
        )
      end
      # some of the below values are hardcoded in the veteran factory
      let!(:inflated_bgs_veteran_record) do
        { first_name: appeal.veteran.first_name,
          last_name: appeal.veteran.last_name,
          date_of_birth: 30.years.ago.to_date.strftime("%m/%d/%Y"),
          date_of_death: nil,
          name_suffix: appeal.veteran.name_suffix,
          sex: "M",
          address_line1: "1234 Main Street",
          country: "USA",
          zip_code: "12345",
          state: "FL",
          city: "Orlando",
          file_number: appeal.veteran.file_number,
          ssn: appeal.veteran.ssn,
          email_address: "#{appeal.veteran.first_name}.#{appeal.veteran.last_name}@test.com",
          ptcpnt_id: appeal.veteran.participant_id,
          participant_id: appeal.veteran.participant_id }
      end
      let!(:bgs) { Fakes::BGSService.new }

      before do
        bgs.class.mark_veteran_not_accessible(appeal.veteran_file_number)
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info)
          .and_raise(BGS::ShareError, "NonUniqueResultException")
      end

      scenario "access the appeal's case details" do
        reload_case_detail_page(appeal.external_id)
        using_wait_time(5) do
          expect(page).to have_content(COPY::DUPLICATE_PHONE_NUMBER_TITLE)
        end

        bgs.inaccessible_appeal_vbms_ids = []
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info)
          .and_return(inflated_bgs_veteran_record)

        visit "/queue/appeals/#{appeal.external_id}"
        expect(page).to have_content(appeal.veteran_full_name)
      end
    end
  end

  context "when an appeal has some number of documents" do
    let!(:appeal) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: create(:case_with_soc, :assigned, :docs_in_vbms, user: attorney_user)
      )
    end

    context "with reader role" do
      before { attorney_user.update!(roles: attorney_user.roles + ["Reader"]) }
      after { attorney_user.update!(roles: attorney_user.roles - ["Reader"]) }

      scenario "reader link appears on page and sends us to reader" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
        click_on "View #{appeal.documents.count} docs"

        expect(page).to have_content("CaseflowQueue")
        expect(page).to have_content("Back to your cases\n#{appeal.veteran_full_name}")
      end
    end

    context "with ro view hearing schedule role" do
      let(:roles) { ["RO ViewHearSched"] }
      let!(:attorney_user) { create(:user, roles: roles) }

      scenario "reader link does not appear on page" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
        expect(page).to have_content COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL
        expect(page).to_not have_content COPY::CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE.upcase
        expect(page).to_not have_content "View #{appeal.documents.count} docs"
      end

      context "also with build hearing schedule role" do
        let(:roles) { ["RO ViewHearSched", "Build HearSched"] }

        scenario "reader link appears on page" do
          visit "/queue"
          click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
          expect(page).to have_content COPY::CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE.upcase
          expect(page).to have_content "View #{appeal.documents.count} docs"
        end
      end

      context "also with edit hearing schedule role" do
        let(:roles) { ["RO ViewHearSched", "Edit HearSched"] }

        scenario "reader link appears on page" do
          visit "/queue"
          click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
          expect(page).to have_content COPY::CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE.upcase
          expect(page).to have_content "View #{appeal.documents.count} docs"
        end
      end
    end
  end

  context "when an appeal has an issue with an allowed disposition" do
    let!(:appeal) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: create(
          :case,
          :assigned,
          user: attorney_user,
          case_issues: [create(:case_issue, :disposition_allowed)]
        )
      )
    end

    scenario "case details page shows appropriate text" do
      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
      # Call have_content() so we wait for the case details page to load
      expect(page).to have_content(appeal.veteran_full_name)
      expect(page).to have_content("DISPOSITION\n1 - Allowed")
    end
  end

  context "when an appeal has an issue that is ineligible" do
    let(:issues) do
      [
        build_list(
          :request_issue,
          1,
          contested_issue_description: "Knee pain"
        ),
        build_list(
          :request_issue,
          1,
          contested_issue_description: "Sunburn",
          ineligible_reason: :untimely
        )
      ].flatten
    end
    let!(:appeal) { create(:appeal, request_issues: issues) }

    scenario "only eligible issues should appear in case details page" do
      visit "/queue/appeals/#{appeal.uuid}"

      expect(page).to have_content("Knee pain")
      expect(page).to_not have_content("Sunburn")
    end
  end

  context "when an appeal has an issue that is decided" do
    let(:issues) do
      [
        build_list(
          :request_issue,
          1,
          contested_issue_description: "Knee pain"
        ),
        build_list(
          :request_issue,
          1,
          contested_issue_description: "Sunburn",
          closed_status: :decided,
          closed_at: 2.days.ago
        )
      ].flatten
    end
    let!(:appeal) { create(:appeal, request_issues: issues) }

    scenario "decided issues should appear in case details page" do
      visit "/queue/appeals/#{appeal.uuid}"

      expect(page).to have_content("Knee pain")
      expect(page).to have_content("Sunburn")
    end
  end

  context "when an appeal has been cancelled" do
    let!(:appeal) do
      create(:appeal, :at_judge_review, associated_judge: judge_user, associated_attorney: attorney_user)
    end

    it "does not show assigned attorney or judge" do
      visit "/queue/appeals/#{appeal.uuid}"
      expect(page).to have_content(judge_user.full_name)
      expect(page).to have_content(attorney_user.full_name)

      appeal.tasks.open.update_all(status: Constants.TASK_STATUSES.cancelled)

      visit "/queue/appeals/#{appeal.uuid}"
      expect(page).to have_content(COPY::TASK_SNAPSHOT_NO_ACTIVE_LABEL)
      expect(page).to have_no_content(judge_user.full_name)
      expect(page).to have_no_content(attorney_user.full_name)
    end
  end

  context "loads judge task detail views" do
    let!(:vacols_case) do
      create(
        :case,
        :assigned,
        user: judge_user,
        assigner: attorney_user,
        correspondent: create(:correspondent, snamef: "Feffy", snamel: "Smeterino"),
        document_id: "1234567890"
      )
    end

    before do
      User.authenticate!(user: judge_user)
    end

    scenario "displays who prepared task" do
      task = LegacyWorkQueue.tasks_for_user(judge_user).first
      appeal = task.appeal

      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

      preparer_name = "#{task.assigned_by.first_name[0]}. #{task.assigned_by.last_name}"

      # Wait for page to load some known content before testing for expected content.
      expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
      edit_link_url = "/queue/appeals/#{appeal.external_id}/modal/advanced_on_docket_motion"
      expect(page).to_not have_link("Edit", href: edit_link_url)
      expect(page.document.text).to match(/#{COPY::TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL.upcase}\n#{preparer_name}/i)
      expect(page.document.text).to match(/#{COPY::TASK_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}\n#{task.document_id}/i)
    end
  end

  context "when events are present" do
    let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let!(:vacols_case) do
      create(
        :case,
        bfdnod: 2.days.ago,
        bfd19: 1.day.ago
      )
    end

    before do
      User.authenticate!(user: judge_user)
    end

    scenario "displays case timeline" do
      visit "/queue/appeals/#{appeal.external_id}"

      # Ensure we see a timeline where completed things are checked and incomplete are gray
      expect(find("tr", text: COPY::CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING)).to have_selector(".gray-dot")
      expect(find("tr", text: COPY::CASE_TIMELINE_FORM_9_RECEIVED)).to have_selector(".green-checkmark")
    end

    context "when appeal is assigned to Pulac Cerullo" do
      let!(:appeal) do
        create(
          :appeal,
          veteran_file_number: "500000102",
          receipt_date: 6.months.ago.to_date.mdY,
          docket_type: Constants.AMA_DOCKETS.evidence_submission
        )
      end

      let!(:decision_document) do
        create(
          :decision_document,
          appeal: appeal,
          decision_date: 5.months.ago.to_date
        )
      end

      let!(:pulac_cerullo) do
        create(
          :pulac_cerullo_task,
          :completed,
          instructions: ["completed"],
          closed_at: 45.days.ago,
          appeal: appeal
        )
      end

      scenario "displays Pulac Cerullo task in order on  case timeline" do
        visit "/queue/appeals/#{appeal.external_id}"

        case_timeline_rows = page.find_all("table#case-timeline-table tbody tr")
        first_row_with_task = case_timeline_rows[0]
        second_row_with_task = case_timeline_rows[1]
        third_row_with_task = case_timeline_rows[2]
        expect(first_row_with_task).to have_content("PulacCerulloTask completed")
        expect(second_row_with_task).to have_content(COPY::CASE_TIMELINE_DISPATCHED_FROM_BVA)
        expect(third_row_with_task).to have_content(COPY::CASE_TIMELINE_NOD_RECEIVED)
      end
    end

    context "when the appeal has hidden colocated tasks" do
      let(:appeal) { create(:appeal) }

      let!(:transcript_task) do
        create(:ama_colocated_task, :missing_hearing_transcripts, appeal: appeal).tap do |task|
          task.children.first.update!(status: Constants.TASK_STATUSES.completed)
        end
      end

      let!(:translation_task) do
        create(:ama_colocated_task, :translation, appeal: appeal).tap do |task|
          task.children.first.update!(status: Constants.TASK_STATUSES.completed)
        end
      end

      let!(:foia_task) do
        create(:ama_colocated_task, :foia, appeal: appeal).tap do |task|
          task.children.first.update!(status: Constants.TASK_STATUSES.completed)
        end
      end

      it "Does not display the intermediate colocated tasks" do
        visit "/queue/appeals/#{appeal.external_id}"

        case_timeline = page.find("table#case-timeline-table")
        expect(case_timeline.has_no_content?(transcript_task.class.name)).to eq(true)
        expect(case_timeline.has_no_content?(translation_task.class.name)).to eq(true)
        expect(case_timeline.has_no_content?(foia_task.class.name)).to eq(true)
        expect(case_timeline).to have_content(transcript_task.children.first.class.name)
        expect(case_timeline).to have_content(translation_task.children.first.class.name)
        expect(case_timeline).to have_content(foia_task.children.first.class.name)
      end
    end
  end

  context "when there is a dispatch and decision_date" do
    let(:vacols_case) do
      create(:case, bfkey: "654321",
                    bfddec: 1.day.ago,
                    bfdnod: 2.days.ago,
                    bfd19: 1.day.ago)
    end
    let(:appeal) do
      create(:legacy_appeal, vacols_case: vacols_case)
    end

    before do
      User.authenticate!(user: judge_user)
    end

    scenario "ensure that the green checkmark appears next to the appropriate message when there is a decision date" do
      visit "/queue/appeals/#{appeal.external_id}"
      expect(find("tr", text: COPY::CASE_TIMELINE_DISPATCHED_FROM_BVA)).to have_selector(".green-checkmark")
      expect(find("tr", text: COPY::CASE_TIMELINE_FORM_9_RECEIVED)).to have_selector(".green-checkmark")
    end
  end

  context "loads colocated task detail views" do
    let!(:appeal) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: create(
          :case,
          :assigned,
          user: colocated_user,
          case_issues: create_list(:case_issue, 1)
        )
      )
    end

    before do
      User.authenticate!(user: colocated_user)
    end

    context "on hold task" do
      let!(:on_hold_task) do
        create(
          :colocated_task,
          :on_hold,
          assigned_to: colocated_user,
          assigned_by: attorney_user
        )
      end

      scenario "displays task information" do
        visit "/queue"

        vet_name = on_hold_task.appeal.veteran_full_name
        assigner_name = on_hold_task.assigned_by_display_name

        click_on "On hold (1)"
        click_on "#{vet_name} (#{on_hold_task.appeal.veteran_file_number})"

        expect(page).to have_content("TASK\n#{on_hold_task.label}")
        find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to have_content("TASK INSTRUCTIONS\n#{on_hold_task.instructions[0].squeeze(' ').strip}")
        expect(page).to have_content("#{assigner_name.first[0]}. #{assigner_name.last}")

        expect(Task.find(on_hold_task.id).status).to eq("on_hold")
      end
    end

    context "assigned task" do
      let!(:assigned_task) do
        create(
          :colocated_task,
          assigned_to: colocated_user,
          assigned_by: attorney_user
        )
      end

      scenario "displays task bold in queue" do
        visit "/queue"
        vet_name = assigned_task.appeal.veteran_full_name
        fontweight_new = get_computed_styles("#veteran-name-for-task-#{assigned_task.id}", "font-weight")
        click_on vet_name
        expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL, wait: 30)
        click_on "Caseflow"
        expect(page).to have_content(COPY::USER_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, wait: 30)
        fontweight_visited = get_computed_styles("#veteran-name-for-task-#{assigned_task.id}", "font-weight")
        expect(fontweight_visited).to be < fontweight_new
      end
    end
  end

  context "edit aod link appears/disappears as expected" do
    let(:appeal) { create(:appeal) }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }

    context "when the current user is a member of the AOD team" do
      before do
        AodTeam.singleton.add_user(user)
        User.authenticate!(user: user)
      end

      context "when requesting the case details page directly" do
        it "should display the edit link" do
          visit("/queue/appeals/#{appeal.external_id}")
          expect(page).to have_content("Edit")
        end
      end

      context "when reaching the case details page by way of the search page" do
        it "should display the edit link" do
          visit("/search")
          fill_in("searchBarEmptyList", with: appeal.veteran.file_number)
          click_on("Search")

          click_on(appeal.docket_number)
          expect(find("#caseTitleDetailsSubheader")).to have_content("Edit")
        end
      end
    end

    context "when the current user is not a member of the AOD team" do
      before do
        allow_any_instance_of(AodTeam).to receive(:user_has_access?).with(user2).and_return(false)
        User.authenticate!(user: user2)
        visit("/queue/appeals/#{appeal.uuid}")
      end
      it "should not display the edit link" do
        expect(find("#caseTitleDetailsSubheader")).to_not have_content("Edit")
      end
    end
  end

  context "When a current user is a member of Supervisory Senior Council organization" do
    let(:appeal) { create(:appeal) }
    let(:current_user) { create(:user) }
    let!(:organization) { SupervisorySeniorCouncil.singleton }
    let!(:organization_user) { OrganizationsUser.make_user_admin(current_user, organization) }
    let(:receipt_date) { Time.zone.today - 20.days }
    let(:profile_date) { (receipt_date - 30.days).to_datetime }
    let(:rating_request_issue_attributes) do
      {
        decision_review: appeal,
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: profile_date,
        contested_issue_description: "PTSD denied",
        contention_reference_id: "4567"
      }
    end
    let!(:rating_request_issue) { create(:request_issue, rating_request_issue_attributes) }
    let!(:appeal_serializer) { WorkQueue::AppealSerializer.new(appeal, params: { user: current_user }).serializable_hash }
    before do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:split_appeal_workflow)
      visit("/queue/appeals/#{appeal.uuid}")
    end
    it "should display the 'Correct issues' link" do
      expect(page).to have_content("Correct issues")
    end
  end

  context "When a user isn't a member of the Supervisory Senior Council" do
    let(:appeal) { create(:appeal) }
    let(:current_user) { create(:user) }
    let(:receipt_date) { Time.zone.today - 20.days }
    let(:profile_date) { (receipt_date - 30.days).to_datetime }
    let(:rating_request_issue_attributes) do
      {
        decision_review: appeal,
        contested_rating_issue_reference_id: "def456",
        contested_rating_issue_profile_date: profile_date,
        contested_issue_description: "PTSD denied",
        contention_reference_id: "4567"
      }
    end
    let!(:rating_request_issue) { create(:request_issue, rating_request_issue_attributes) }
    let!(:appeal_serializer) { WorkQueue::AppealSerializer.new(appeal, params: { user: current_user }).serializable_hash }
    before do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:split_appeal_workflow)
      visit("/queue/appeals/#{appeal.uuid}")
    end
    it "should not display the 'Correct issues' link" do
      expect(page).to_not have_content("Correct issues")
    end
  end

  describe "Appeal has requested to switch dockets" do
    let!(:full_grant_docket_switch) { create(:docket_switch) }
    let!(:partial_grant_docket_switch) { create(:docket_switch, :partially_granted) }
    let!(:denied_docket_switch) { create(:docket_switch, :denied) }
    context "appeal has received full grant docket switch" do
      it "should display alert banner on old appeal stream page" do
        visit "/queue/appeals/#{full_grant_docket_switch.old_docket_stream.uuid}"
        expect(page).to have_content COPY::DOCKET_SWITCH_FULL_GRANTED_TITLE
        click_link "switched appeal stream."
        expect(page).to have_current_path("/queue/appeals/#{full_grant_docket_switch.new_docket_stream.uuid}")
      end
    end

    context "appeal has received partial grant docket switch" do
      it "should display alert banner on old appeal stream page" do
        visit "/queue/appeals/#{partial_grant_docket_switch.old_docket_stream.uuid}"
        expect(page).to have_content COPY::DOCKET_SWITCH_PARTIAL_GRANTED_TITLE_OLD_DOCKET
        click_link "switched appeal stream."
        expect(page).to have_current_path("/queue/appeals/#{partial_grant_docket_switch.new_docket_stream.uuid}")
      end

      it "should display alert banner on new appeal stream page" do
        visit "/queue/appeals/#{partial_grant_docket_switch.new_docket_stream.uuid}"
        expect(page).to have_content COPY::DOCKET_SWITCH_PARTIAL_GRANTED_TITLE_NEW_DOCKET
        click_link "other appeal stream."
        expect(page).to have_current_path("/queue/appeals/#{partial_grant_docket_switch.old_docket_stream.uuid}")
      end
    end

    context "appeal has been denied request to switch dockets" do
      it "should not display alert banner" do
        visit "/queue/appeals/#{denied_docket_switch.old_docket_stream.uuid}"
        expect(page).to_not have_content COPY::DOCKET_SWITCH_FULL_GRANTED_TITLE
      end
    end
  end

  describe "Marking organization task complete" do
    context "when there is no assigner" do
      let(:qr) { QualityReview.singleton }
      let(:task) { create(:qr_task) }
      let(:user) { create(:user) }

      before do
        # Marking this task complete creates a BvaDispatchTask. Make sure there are members of that organization so
        # that the creation of that BvaDispatchTask succeeds.
        BvaDispatch.singleton.add_user(create(:user))
        qr.add_user(user)
        User.authenticate!(user: user)
      end

      it "marking task as complete works" do
        visit "/queue/appeals/#{task.appeal.uuid}"

        find(".cf-select__control", text: "Select an action").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.label).click

        find("button", text: COPY::MARK_TASK_COMPLETE_BUTTON).click

        expect(page).to have_content(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, "").squeeze(" "))
      end
    end

    describe "Issue order by created_at in Case Details page" do
      context "when there are two issues" do
        let!(:appeal) { create(:appeal) }
        issue_description = "Head trauma 1"
        issue_description2 = "Head trauma 2"
        benefit_text = "Benefit type: Compensation"
        diagnostic_text = "Diagnostic code: 5008"
        let!(:request_issue) do
          create(
            :request_issue,
            decision_review: appeal,
            contested_issue_description: issue_description
          )
        end
        let!(:request_issue2) do
          create(
            :request_issue,
            decision_review: appeal,
            contested_issue_description: issue_description2
          )
        end

        it "should display sorted issues with appropriate key value pairs" do
          visit "/queue/appeals/#{appeal.uuid}"
          issue_key = "Issue: "
          issue_value = issue_description
          issue_text = issue_key + issue_value
          expect(page).to have_content(issue_text)
          expect(page).to have_content(benefit_text)
          expect(page).to have_content(diagnostic_text)

          issue_value = issue_description2
          issue_text = issue_key + issue_value
          expect(page).to have_content(issue_text)
          expect(page).to have_content(benefit_text)
          expect(page).to have_content(diagnostic_text)
        end
      end
    end

    describe "Docket type badge shows up" do
      let!(:appeal) { create(:appeal, docket_type: Constants.AMA_DOCKETS.direct_review) }

      it "should display docket type and number" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content("D\n#{appeal.docket_number}")
      end
    end

    describe "CaseTimeline shows judge & attorney tasks" do
      let!(:user) { create(:user) }
      let!(:nod_date_update) { create(:nod_date_update) }
      let!(:appeal) { create(:appeal, nod_date_updates: [nod_date_update]) }
      let!(:appeal2) { create(:appeal) }
      let!(:root_task) { create(:root_task, appeal: appeal, assigned_to: user) }
      let!(:assign_task) { create(:ama_judge_assign_task, assigned_to: user, parent: root_task) }
      let!(:judge_task) do
        create(
          :ama_judge_decision_review_task,
          parent: root_task,
          assigned_to: user
        )
      end
      let!(:attorney_task) { create(:ama_attorney_task, parent: judge_task, assigned_to: user) }

      before do
        FeatureToggle.enable!(:view_nod_date_updates)
        # The status attribute needs to be set here due to update_parent_status hook in the task model
        # the updated_at attribute needs to be set here due to the set_timestamps hook in the task model
        assign_task.update!(status: Constants.TASK_STATUSES.completed, closed_at: "2019-01-01")
        attorney_task.update!(status: Constants.TASK_STATUSES.completed, closed_at: "2019-02-01")
        judge_task.update!(status: Constants.TASK_STATUSES.completed, closed_at: Time.zone.now)
        nod_date_update.update!(updated_at: "2019-01-05")
      end

      after { FeatureToggle.disable!(:view_nod_date_updates) }

      it "should display judge & attorney tasks, but not judge assign tasks" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content(COPY::CASE_TIMELINE_ATTORNEY_TASK)
        expect(page.find_all("dl", text: COPY::CASE_TIMELINE_JUDGE_TASK).length).to eq 1
      end

      it "should sort tasks and nod date updates properly" do
        visit "/queue/appeals/#{appeal.uuid}"
        case_timeline_rows = page.find_all("table#case-timeline-table tbody tr")
        first_row_with_date = case_timeline_rows[1]
        second_row_with_date = case_timeline_rows[2]
        third_row_with_date = case_timeline_rows[3]
        expect(first_row_with_date).to have_content("01/01/2020")
        expect(second_row_with_date).to have_content("02/01/2019")
        expect(third_row_with_date).to have_content("01/05/2019")
      end

      it "should NOT display judge & attorney tasks" do
        visit "/queue/appeals/#{appeal2.uuid}"
        expect(page.has_no_content?(COPY::CASE_TIMELINE_JUDGE_TASK)).to eq(true)
      end
    end
  end

  describe "AMA decision issue notes" do
    let(:request_issue) { create(:request_issue, contested_issue_description: "knee pain", notes: notes) }
    let(:appeal) { create(:appeal, number_of_claimants: 1, request_issues: [request_issue]) }

    context "when notes are nil" do
      let(:notes) { nil }

      it "does not display the Notes div" do
        visit "/queue/appeals/#{appeal.uuid}"

        expect(page).to_not have_content("Note:")
      end
    end

    context "when notes are empty" do
      let(:notes) { "" }

      it "does not display the Notes div" do
        visit "/queue/appeals/#{appeal.uuid}"

        expect(page).to_not have_content("Note:")
      end
    end
  end

  describe "Show multiple tasks" do
    let(:appeal) { create(:appeal) }
    let!(:root_task) do
      create(:root_task, appeal: appeal, assigned_to: judge_user)
    end
    let(:instructions_text) { "note #1" }
    let!(:task) do
      create(:task,
             :in_progress,
             appeal: appeal,
             assigned_by: judge_user,
             assigned_to: attorney_user,
             type: Task,
             parent_id: root_task.id,
             started_at: rand(1..10).days.ago,
             instructions: [instructions_text])
    end

    context "single task" do
      it "one task is displayed in the TaskSnapshot" do
        visit "/queue/appeals/#{appeal.uuid}"

        expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
        expect(page).to have_content(task.assigned_at.strftime("%m/%d/%Y"))
        expect(page).to have_content("#{COPY::TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL.upcase}\n#{task.assigned_to.css_id}")
        expect(page).to have_content(COPY::TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL.upcase)
        expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTION_BOX_TITLE)
      end
      it "Show/hide task instructions" do
        visit "/queue/appeals/#{appeal.uuid}"

        find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to have_content(instructions_text)
        find("button", text: COPY::TASK_SNAPSHOT_HIDE_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to_not have_content(instructions_text)
      end

      context "with single line break in instructions" do
        let(:instructions_text) { "Lorem ipsum dolor sit amet,\nconsectetur adipiscing elit" }

        it "displays with <br>" do
          visit "/queue/appeals/#{appeal.uuid}"

          find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
          div = find("div.task-instructions")
          div.assert_selector("br", count: 1, visible: false)
          expect(div).to have_text(instructions_text)
        end
      end

      context "with multiple line breaks separating text in instructions" do
        let(:instructions_text) { "Lorem ipsum dolor sit amet,\n\nconsectetur adipiscing elit" }
        let(:split) { instructions_text.split(/\n\n/) }

        it "displays with <p> tags" do
          visit "/queue/appeals/#{appeal.uuid}"

          find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
          div = find("div.task-instructions")
          div.assert_selector("p", count: 2)
          expect(div.find_all("p")[0]).to have_text(split[0])
          expect(div.find_all("p")[1]).to have_text(split[1])
        end
      end
    end
    context "multiple tasks" do
      let!(:task2) do
        create(:task, :in_progress, appeal: appeal,
                                    assigned_by: judge_user, assigned_to: attorney_user, type: AttorneyTask,
                                    parent_id: task.id, started_at: rand(1..20).days.ago)
      end
      let!(:task3) do
        create(:task, :in_progress, appeal: appeal,
                                    assigned_by: judge_user, assigned_to: attorney_user, type: AttorneyTask,
                                    parent_id: task.id, started_at: rand(1..20).days.ago, assigned_at: 15.days.ago)
      end
      it "two tasks are displayed in the TaskSnapshot" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content(task2.assigned_at.strftime("%m/%d/%Y"))
        expect(page).to have_content(task2.assigned_to.css_id)
        expect(page).to have_content(task3.assigned_at.strftime("%m/%d/%Y"))
        expect(page).to have_content(task3.assigned_to.css_id)

        assignment_date_label = COPY::TASK_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL.upcase
        assigned_at_date = task2.assigned_at.strftime("%m/%d/%Y")
        days_since_label = COPY::TASK_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL.upcase
        assigned_on_text = "#{assignment_date_label}\n#{assigned_at_date}\n#{days_since_label}"

        expect(page).to have_content(assigned_on_text)

        assignee_label = COPY::TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL.upcase
        assigned_to = task3.assigned_to.css_id
        assignor_label = COPY::TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL.upcase
        assigned_to_text = "#{assignee_label}\n#{assigned_to}\n#{assignor_label}"

        expect(page).to have_content(assigned_to_text)
      end
    end
  end

  describe "Persist legacy tasks from backend" do
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

    context "one task" do
      let!(:root_task) do
        create(:root_task, appeal: legacy_appeal, assigned_to: judge_user)
      end
      let!(:legacy_task) do
        create(:task, :in_progress, appeal: legacy_appeal,
                                    assigned_by: judge_user, assigned_to: attorney_user, type: Task,
                                    parent_id: root_task.id, started_at: rand(1..10).days.ago)
      end

      it "is displayed in the TaskSnapshot" do
        visit "/queue/appeals/#{legacy_appeal.vacols_id}"
        expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
        expect(page).to have_content(legacy_task.assigned_at.strftime("%m/%d/%Y"))
      end
    end
  end

  describe "VLJ and Attorney working case in Universal Case Title" do
    let(:attorney_user) { create(:user) }
    let(:judge_user) { create(:user) }
    let(:root_task) { create(:root_task) }
    let(:appeal) { root_task.appeal }
    let!(:request_issue) { create(:request_issue, decision_review: appeal) }
    let!(:judge_task) do
      create(
        :ama_judge_decision_review_task,
        appeal: appeal,
        parent: root_task,
        assigned_by: judge_user,
        assigned_to: judge_user
      )
    end
    let!(:atty_task) do
      create(
        :ama_attorney_task,
        appeal: appeal,
        parent: judge_task,
        assigned_by: judge_user,
        assigned_to: attorney_user
      )
    end
    context "Attorney has been assigned" do
      it "is displayed in the Universal Case Title" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content(COPY::TASK_SNAPSHOT_ASSIGNED_JUDGE_LABEL)
        expect(page).to have_content(judge_user.full_name)
        expect(page).to have_content(COPY::TASK_SNAPSHOT_ASSIGNED_ATTORNEY_LABEL)
        expect(page).to have_content(attorney_user.full_name)
      end
    end

    context "Attorney has removed appeal" do
      before { request_issue.remove! }
      it "should not show attorney name" do
        expect(appeal.reload.removed?).to eq(true)
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to_not have_content(judge_user.full_name)
        expect(page).to_not have_content(attorney_user.full_name)
      end
    end
  end

  describe "contested claim" do
    before { FeatureToggle.enable!(:indicator_for_contested_claims) }
    after { FeatureToggle.disable!(:indicator_for_contested_claims) }

    it "should show the contested claim badge" do
      request_issues = [create(:request_issue,
                               benefit_type: "compensation",
                               nonrating_issue_category: "Contested Claims - Insurance"),
                        create(:request_issue, :rating, benefit_type: "fiduciary")]
      appeal = create(:appeal, request_issues: request_issues)
      tracking_task = create(:track_veteran_task,
                             :completed,
                             appeal: appeal,
                             parent: appeal.root_task)

      visit("/queue/appeals/#{tracking_task.appeal.uuid}")
      expect(page).to have_selector(".cf-contested-badge")

      page.all("a", text: "View all cases").first.click
      case_table = find(".cf-case-list-table")
      expect(case_table).to have_selector(".cf-contested-badge")
    end
  end

  describe "case timeline" do
    context "when the only completed task is a TrackVeteranTask" do
      let(:appeal) { create(:appeal) }
      let!(:tracking_task) do
        create(
          :track_veteran_task,
          :completed,
          appeal: appeal,
          parent: appeal.root_task
        )
      end

      it "should not show the tracking task in case timeline" do
        visit("/queue/appeals/#{tracking_task.appeal.uuid}")
        # Expect to only find the "NOD received" row and the "dispatch pending" rows.
        expect(page).to have_css("table#case-timeline-table tbody tr", count: 2)
      end

      context "has withdrawn decision reviews" do
        let(:veteran) do
          create(:veteran,
                 first_name: "Bob",
                 last_name: "Winters",
                 file_number: "55555456")
        end

        let!(:appeal) do
          create(:appeal,
                 :with_post_intake_tasks,
                 veteran_file_number: veteran.file_number,
                 docket_type: Constants.AMA_DOCKETS.direct_review,
                 receipt_date: 10.months.ago.to_date.mdY)
        end

        let!(:request_issue) do
          create(
            :request_issue,
            decision_review: appeal,
            contested_issue_description: "Left Knee",
            benefit_type: "compensation",
            decision_date: 8.months.ago.to_date.mdY,
            closed_status: "withdrawn",
            closed_at: 7.days.ago.to_datetime
          )
        end

        before do
          appeal.root_task.update!(status: Constants.TASK_STATUSES.cancelled)
        end

        scenario "withdraw entire review and show withdrawn on case timeline" do
          visit "/queue/appeals/#{appeal.uuid}"

          expect(page).to have_content(COPY::TASK_SNAPSHOT_TASK_WITHDRAWAL_DATE_LABEL.upcase)
          expect(page).to have_content("Appeal withdrawn")
        end
      end
    end

    context "when POA changes and IHP task is cancelled" do
      let(:old_poa) { create(:vso, name: "Old POA") }
      let(:appeal) do
        create(:appeal, veteran: create(:veteran)) do |appeal|
          create(
            :informal_hearing_presentation_task,
            appeal: appeal,
            assigned_to: old_poa
          )
        end
      end
      let(:new_poa_participant_id) { "2222222" }
      let!(:new_poa) { create(:vso, name: "New POA", participant_id: new_poa_participant_id) }
      let!(:bgs_poa_for_claimant) do
        create(:bgs_power_of_attorney,
               claimant_participant_id: appeal.claimant.participant_id,
               poa_participant_id: new_poa_participant_id)
      end
      it "should show the cancelled task in case timeline with the appropriate reason" do
        InformalHearingPresentationTask.update_to_new_poa(appeal)
        visit("/queue/appeals/#{appeal.uuid}")
        expect(page).to have_css("table#case-timeline-table tbody tr", count: 3)
        expect(page).to have_content(COPY::TASK_SNAPSHOT_CANCEL_REASONS["poa_change"])
      end
    end

    context "when an AMA appeal has been dispatched from the Board" do
      let(:appeal) { create(:appeal) }
      let(:root_task) { create(:root_task, appeal: appeal) }

      before do
        judge = create(:user, station_id: 101)
        create(:staff, :judge_role, user: judge)
        judge_task = JudgeAssignTask.create!(appeal: appeal, parent: root_task, assigned_to: judge)

        atty = create(:user, station_id: 101)
        create(:staff, :attorney_role, user: atty)
        atty_task_params = [{ appeal: appeal, parent_id: judge_task.id, assigned_to: atty, assigned_by: judge }]
        atty_task = AttorneyTask.create_many_from_params(atty_task_params, judge).first

        atty_task.update!(status: Constants.TASK_STATUSES.completed)
        judge_task.update!(status: Constants.TASK_STATUSES.completed)

        bva_dispatcher = create(:user)
        BvaDispatch.singleton.add_user(bva_dispatcher)
        BvaDispatchTask.create_from_root_task(root_task)

        params = {
          appeal_id: appeal.external_id,
          citation_number: "12312312",
          decision_date: Date.new(1989, 11, 9).to_s,
          file: "longfilenamehere",
          redacted_document_location: "C://Windows/User/BVASWIFTT/Documents/NewDecision.docx"
        }
        BvaDispatchTask.outcode(appeal, params, bva_dispatcher)
      end

      it "displays the correct elements in case timeline" do
        visit("/queue/appeals/#{appeal.uuid}")

        expect(page).to_not have_content(root_task.timeline_title)
        expect(page).to_not have_content(COPY::CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING)
        expect(page).to_not have_css(".gray-dot")

        expect(page).to have_content(COPY::CASE_TIMELINE_DISPATCHED_FROM_BVA)
      end
    end

    context "when a NOD exists and the case is a legacy case, do not display Edit NOD Date link" do
      before { FeatureToggle.enable!(:edit_nod_date) }
      after { FeatureToggle.disable!(:edit_nod_date) }

      let(:judge_user) { create(:user, css_id: "BVAAABSHIRE", station_id: "101") }
      let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
      let!(:vacols_case) do
        create(
          :case,
          bfdnod: 2.days.ago,
          bfd19: 1.day.ago
        )
      end

      before do
        User.authenticate!(user: judge_user)
      end

      it "displays case timeline and does not display Edit NOD Date link for legacy cases" do
        visit "/queue/appeals/#{appeal.external_id}"
        expect(appeal.nod_date).to_not be_nil
        expect(page).to have_content(COPY::CASE_TIMELINE_NOD_RECEIVED)
        expect(page).to_not have_content(COPY::CASE_DETAILS_EDIT_NOD_DATE_LINK_COPY)
      end
    end

    context "when a NOD exists and user can edit NOD date display Edit NOD Date link" do
      before { FeatureToggle.enable!(:edit_nod_date) }
      after { FeatureToggle.disable!(:edit_nod_date) }

      let(:appeal) { create(:appeal) }
      let(:veteran) do
        create(:veteran,
               first_name: "Bobby",
               last_name: "Winters",
               file_number: "55555456")
      end

      let!(:appeal) do
        create(:appeal,
               :with_post_intake_tasks,
               veteran_file_number: veteran.file_number,
               docket_type: Constants.AMA_DOCKETS.direct_review,
               receipt_date: 10.months.ago.to_date.mdY)
      end

      context "when the user is a COB_USER" do
        let(:cob_user) { create(:user, css_id: "COB_USER", station_id: "101") }

        before do
          ClerkOfTheBoard.singleton.add_user(cob_user)
          User.authenticate!(user: cob_user)
        end

        it "displays Edit NOD Date link" do
          visit("/queue/appeals/#{appeal.uuid}")

          expect(appeal.nod_date).to_not be_nil
          expect(page).to have_content(COPY::CASE_TIMELINE_NOD_RECEIVED)
          expect(page).to have_content(COPY::CASE_DETAILS_EDIT_NOD_DATE_LINK_COPY)
        end

        it "creates an Edit NOD Date entry and a success alert displays after a successful change" do
          visit("/queue/appeals/#{appeal.uuid}")

          find("button", text: COPY::CASE_DETAILS_EDIT_NOD_DATE_LINK_COPY).click
          fill_in COPY::EDIT_NOD_DATE_LABEL, with: Time.zone.today.mdY

          expect(page).to have_content("Reason for edit")
          find(".cf-form-dropdown", text: "Reason for edit").click
          find(:css, "input[id$='reason']").set("New Form/Information Received").send_keys(:return)
          safe_click "#Edit-NOD-Date-button-id-1"

          expect(page).to have_content(
            format(COPY::EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE.tr("(", "{").gsub(")s", "}"),
                   appellantName: appeal.claimant.name,
                   nodDateStr: appeal.receipt_date.mdY,
                   receiptDateStr: Time.zone.today.mdY)
          )
        end
      end

      context "when the user is an attorney" do
        let(:attorney_user) { create(:user, css_id: "BVASCASPER1", station_id: "101") }

        before do
          User.authenticate!(user: attorney_user)
        end

        it "displays Edit NOD Date link" do
          visit("/queue/appeals/#{appeal.uuid}")

          expect(appeal.nod_date).to_not be_nil
          expect(page).to have_content(COPY::CASE_TIMELINE_NOD_RECEIVED)
          expect(page).to_not have_content(COPY::CASE_DETAILS_EDIT_NOD_DATE_LINK_COPY)
        end
      end

      context "when the user is a judge" do
        let(:judge_user) { create(:user, css_id: "BVAOSHOWALT", station_id: "101") }

        before do
          User.authenticate!(user: judge_user)
        end

        it "displays Edit NOD Date link" do
          visit("/queue/appeals/#{appeal.uuid}")

          expect(appeal.nod_date).to_not be_nil
          expect(page).to have_content(COPY::CASE_TIMELINE_NOD_RECEIVED)
          expect(page).to_not have_content(COPY::CASE_DETAILS_EDIT_NOD_DATE_LINK_COPY)
        end
      end

      context "when the user is an Intake User" do
        let(:intake_user) { create(:user, css_id: "BVAISHAW", station_id: "101") }

        before do
          BvaIntake.singleton.add_user(intake_user)
          User.authenticate!(user: intake_user)
        end

        it "displays Edit NOD Date link" do
          visit("/queue/appeals/#{appeal.uuid}")

          expect(appeal.nod_date).to_not be_nil
          expect(page).to have_content(COPY::CASE_TIMELINE_NOD_RECEIVED)
          expect(page).to_not have_content(COPY::CASE_DETAILS_EDIT_NOD_DATE_LINK_COPY)
        end
      end

      context "when the user clicks on the edit nod button" do
        let(:cob_user) { create(:user, css_id: "COB_USER", station_id: "101") }

        before do
          ClerkOfTheBoard.singleton.add_user(cob_user)
          User.authenticate!(user: cob_user)
        end

        let(:veteran_full_name) { veteran.first_name + veteran.last_name }
        let(:nod_date) { "11/11/2020" }
        let(:later_nod_date) { (frontend_time + 2.days).mdY }
        let(:before_earliest_date) { "12/31/2017" }
        before { FeatureToggle.enable!(:edit_nod_date) }
        after { FeatureToggle.disable!(:edit_nod_date) }

        it "user enters an NOD Date after original NOD Date" do
          visit "queue/appeals/#{appeal.uuid}"
          page.find("button", text: "Edit NOD Date").click
          find_field "nodDate"
          fill_in "nodDate", with: nod_date
          find(".cf-form-dropdown", text: "Reason for edit").click
          find(:css, "input[id$='reason']").set("New Form/Information Received").send_keys(:return)
          expect(page).to have_content COPY::EDIT_NOD_DATE_WARNING_ALERT_MESSAGE
        end

        it "user enters a future NOD Date" do
          visit "queue/appeals/#{appeal.uuid}"
          page.find("button", text: "Edit NOD Date").click
          find_field "nodDate"
          fill_in "nodDate", with: later_nod_date
          find(".cf-form-dropdown", text: "Reason for edit").click
          find(:css, "input[id$='reason']").set("New Form/Information Received").send_keys(:return)
          expect(page).to have_content COPY::EDIT_NOD_DATE_FUTURE_DATE_ERROR_MESSAGE
          click_on "Submit"
          expect(page).to_not have_content COPY::EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE
        end

        it "user enters an NOD Date before 01/01/2018" do
          visit "queue/appeals/#{appeal.uuid}"
          page.find("button", text: "Edit NOD Date").click
          find_field "nodDate"
          fill_in "nodDate", with: before_earliest_date
          find(".cf-form-dropdown", text: "Reason for edit").click
          find(:css, "input[id$='reason']").set("New Form/Information Received").send_keys(:return)
          expect(page).to have_content COPY::EDIT_NOD_DATE_PRE_AMA_DATE_ERROR_MESSAGE
          click_on "Submit"
          expect(page).to_not have_content COPY::EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE
        end

        it "user enters a reason with invalid Date" do
          visit "queue/appeals/#{appeal.uuid}"
          page.find("button", text: "Edit NOD Date").click
          find_field "nodDate"
          fill_in "nodDate", with: nod_date
          find(:css, "input[id$='nodDate']").click.send_keys(:delete)
          find(".cf-form-dropdown", text: "Reason for edit").click
          find(:css, "input[id$='reason']").set("New Form/Information Received").send_keys(:return)
          expect(page).to have_content "Invalid date."
          click_on "Submit"
          expect(page).to_not have_content COPY::EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE
        end

        it "user enters a valid NOD Date and reason" do
          visit "queue/appeals/#{appeal.uuid}"
          page.find("button", text: "Edit NOD Date").click
          find_field "nodDate"
          fill_in "nodDate", with: nod_date
          find(".cf-form-dropdown", text: "Reason for edit").click
          find(:css, "input[id$='reason']").set("New Form/Information Received").send_keys(:return)
          click_on "Submit"
          expect(page).to have_content(format(COPY::EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE
                                              .tr("(", "{").gsub(")s", "}"),
                                              appellantName: "Bobby Winters",
                                              nodDateStr: "01/03/2019",
                                              receiptDateStr: nod_date))
        end

        it "user enters a valid NOD Date but no reason" do
          visit "queue/appeals/#{appeal.uuid}"
          page.find("button", text: "Edit NOD Date").click
          find_field "nodDate"
          fill_in "nodDate", with: nod_date
          click_on "Submit"
          expect(page).to have_content "Required."
          expect(page).to_not have_content COPY::EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE
        end
      end
    end

    context "when a NOD exists and user cannot edit NOD date do not display Edit NOD Date link" do
      before { FeatureToggle.enable!(:edit_nod_date) }
      after { FeatureToggle.disable!(:edit_nod_date) }

      let(:appeal) { create(:appeal) }
      let(:veteran) do
        create(:veteran,
               first_name: "Bobby",
               last_name: "Winters",
               file_number: "55555456")
      end

      let!(:appeal) do
        create(:appeal,
               :with_post_intake_tasks,
               veteran_file_number: veteran.file_number,
               docket_type: Constants.AMA_DOCKETS.direct_review,
               receipt_date: 10.months.ago.to_date.mdY)
      end

      let(:not_cob_user) { create(:user, css_id: "BVAAABSHIRE", station_id: "101") }

      before do
        BvaDispatch.singleton.add_user(not_cob_user)
        User.authenticate!(user: not_cob_user)
      end

      it "does not display the Edit NOD Date link" do
        visit("/queue/appeals/#{appeal.uuid}")

        expect(appeal.nod_date).to_not be_nil
        expect(page).to have_content(COPY::CASE_TIMELINE_NOD_RECEIVED)
        expect(page).to_not have_content(COPY::CASE_DETAILS_EDIT_NOD_DATE_LINK_COPY)
      end
    end

    context "when a NOD exists and user can edit NOD date but triggers timeliness issues with NOD date update" do
      let(:veteran) do
        create(:veteran,
               first_name: "Bobby",
               last_name: "Winters",
               file_number: "55555456")
      end
      let(:untimely_request_issue) { create(:request_issue, :nonrating, id: 1, decision_date: 381.days.ago) }
      let(:untimely_request_issue_with_exemption) do
        create(:request_issue, :nonrating, id: 2, decision_date: 2.years.ago, untimely_exemption: true)
      end
      let(:request_issues) { [untimely_request_issue, untimely_request_issue_with_exemption] }

      let!(:appeal) do
        create(:appeal,
               :with_post_intake_tasks,
               veteran_file_number: veteran.file_number,
               docket_type: Constants.AMA_DOCKETS.direct_review,
               receipt_date: 10.months.ago.to_date.mdY,
               request_issues: request_issues)
      end
      subject { appeal.untimely_issues_report(receipt_date) }
      let(:cob_user) { create(:user, css_id: "COB_USER", station_id: "101") }

      before do
        FeatureToggle.enable!(:edit_nod_date)
        ClerkOfTheBoard.singleton.add_user(cob_user)
        User.authenticate!(user: cob_user)
      end

      after { FeatureToggle.disable!(:edit_nod_date) }

      it "displays timeliness issues list if new NOD date causes timely issue to be untimely" do
        visit("/queue/appeals/#{appeal.uuid}")

        expect(appeal.nod_date).to_not be_nil
        expect(page).to have_content(COPY::CASE_TIMELINE_NOD_RECEIVED)
        expect(page).to have_content(COPY::CASE_DETAILS_EDIT_NOD_DATE_LINK_COPY)

        find("button", text: COPY::CASE_DETAILS_EDIT_NOD_DATE_LINK_COPY).click
        fill_in COPY::EDIT_NOD_DATE_LABEL, with: Time.zone.today.mdY

        expect(page).to have_content("Reason for edit")
        find(".cf-form-dropdown", text: "Reason for edit").click
        find(:css, "input[id$='reason']").set("New Form/Information Received").send_keys(:return)
        safe_click "#Edit-NOD-Date-button-id-1"

        expect(page).to have_content(COPY::EDIT_NOD_DATE_TIMELINESS_ERROR_MESSAGE)

        affected_issues_list = page.find_all(".cf-modal-body ul.cf-error li")
        unaffected_issues_list = page.find_all(".cf-modal-body ul:not(.cf-error) li")

        issue_one = untimely_request_issue
        issue_two = untimely_request_issue_with_exemption

        issue_one_desc = "#{issue_one.nonrating_issue_category} - #{issue_one.nonrating_issue_description}"
        issue_two_desc = "#{issue_two.nonrating_issue_category} - #{issue_two.nonrating_issue_description}"

        expect(affected_issues_list[0]).to have_content(
          "#{issue_one_desc}\n(Decision Date: #{issue_one.decision_date.to_date.mdY})"
        )
        expect(unaffected_issues_list[0]).to have_content(
          "#{issue_two_desc}\n(Decision Date: #{issue_two.decision_date.to_date.mdY})"
        )
      end
    end

    describe "substitute appellant" do
      describe "The 'Add Substitute' button" do
        let(:docket_type) { "evidence_submission" }
        let(:case_type) { "original" }
        let(:disposition) { "allowed" }
        let(:status) { :dispatched }
        let(:appeal) do
          create(:appeal, status, :with_decision_issue,
                 docket_type: docket_type,
                 stream_type: case_type,
                 disposition: disposition)
        end

        let(:cob_user) { create(:user, css_id: "COB_USER", station_id: "101") }
        before do
          ClerkOfTheBoard.singleton.add_user(cob_user)
          User.authenticate!(user: cob_user)
        end

        shared_examples "the button is not shown" do
          it "the 'Add Substitute' button is not shown" do
            visit "/queue/appeals/#{appeal.external_id}"
            wait_for_page_render
            expect(page).to have_no_content(COPY::SUBSTITUTE_APPELLANT_BUTTON)
          end
        end

        shared_examples "the button is shown" do
          it "the 'Add Substitute' button is shown" do
            visit "/queue/appeals/#{appeal.external_id}"
            wait_for_page_render
            expect(page).to have_content(COPY::SUBSTITUTE_APPELLANT_BUTTON)
          end
        end

        context "When the case type is not 'original'" do
          let(:case_type) { "de_novo" }

          it_behaves_like "the button is not shown"
        end

        context "When the appeal is in post-dispatch state" do
          let(:disposition) { "dismissed_death" }
          let(:status) { :post_dispatch }

          it_behaves_like "the button is shown"
        end

        context "when the docket type is 'hearing'" do
          let(:docket_type) { "hearing" }

          context "when the user is an admin" do
            before { OrganizationsUser.make_user_admin(cob_user, ClerkOfTheBoard.singleton) }
            after { OrganizationsUser.remove_admin_rights_from_user(cob_user, ClerkOfTheBoard.singleton) }

            it_behaves_like "the button is shown"
          end

          context "when the user is not an admin" do
            it_behaves_like "the button is not shown"
          end
        end

        context "when the disposition is 'Dismissed, Death'" do
          let(:disposition) { "dismissed_death" }

          it_behaves_like "the button is shown"

          context "but if the claimant is not a veteran" do
            before { appeal.update(veteran_is_not_claimant: true) }
            it_behaves_like "the button is not shown"
          end
        end

        context "when the disposition is something else" do
          context "when the user is an admin" do
            before { OrganizationsUser.make_user_admin(cob_user, ClerkOfTheBoard.singleton) }
            after { OrganizationsUser.remove_admin_rights_from_user(cob_user, ClerkOfTheBoard.singleton) }

            it_behaves_like "the button is shown"
          end

          context "when the user is not an admin" do
            it_behaves_like "the button is not shown"
          end
        end
      end

      context "when there is a substitute appellant" do
        let(:appeal_sub) { create(:appellant_substitution) }
        let(:new_appeal) { appeal_sub.target_appeal }
        let(:substitution_date) { appeal_sub.substitution_date.strftime("%d/%m/%y") }

        it "shows the substitution date for the appellant" do
          visit "/queue/appeals/#{new_appeal.external_id}"
          expect(page).to have_content("About the Appellant")
          expect(page).to have_content("Substitution granted by the RO")
          expect(page).to have_content(substitution_date)
          expect(page).to have_content(COPY::CASE_TIMELINE_APPELLANT_IS_A_SUBSTITUTE)
        end
      end
    end

    describe "Add CAVC Remand button" do
      let(:docket_type) { "evidence_submission" }
      let(:case_type) { "original" }
      let(:disposition) { "allowed" }

      let(:appeal) do
        create(:appeal, status, :with_decision_issue,
               docket_type: docket_type,
               stream_type: case_type,
               disposition: disposition)
      end
      let(:user) { create(:user, css_id: "CAVC_LIT_USER") }

      before do
        CavcLitigationSupport.singleton.add_user(user)
        User.authenticate!(user: user)
      end

      shared_examples "the button is not shown" do
        it "the 'Add CAVC Remand' button is not shown" do
          visit "/queue/appeals/#{appeal.external_id}"
          wait_for_page_render
          expect(page).to have_no_content(COPY::ADD_CAVC_BUTTON)
        end
      end

      shared_examples "the button is shown" do
        it "The 'Add CAVC Remand' button is shown" do
          visit "/queue/appeals/#{appeal.external_id}"
          wait_for_page_render
          expect(page).to have_content(COPY::ADD_CAVC_BUTTON)
        end
      end

      context "when the appeal is in dispatch state" do
        let(:status) { :dispatched }
        it_behaves_like "the button is shown"
      end

      context "when the appeal is in post-dispatch state" do
        let(:status) { :post_dispatch }
        it_behaves_like "the button is shown"
      end

      context "when the appeal is not yet dispatched" do
        let(:status) { :assigned_to_judge }
        it_behaves_like "the button is not shown"
      end
    end

    describe "Add CAVC Dashboard button" do
      let(:cavc_decision_type) do
        [
          Constants.CAVC_DECISION_TYPES.straight_reversal,
          Constants.CAVC_DECISION_TYPES.death_dismissal
        ].sample
      end
      let!(:cavc_remand) do
        create(:cavc_remand,
               cavc_decision_type: cavc_decision_type,
               remand_subtype: nil,
               judgement_date: 2.months.ago.to_date.mdY,
               mandate_date: 2.months.ago.to_date.mdY)
      end
      let(:cavc_appeal) { cavc_remand.remand_appeal }

      let(:non_occoai_user) { create(:user, css_id: "BVA_INTAKE_USER", station_id: "101") }
      let(:occ_user) { create(:user, css_id: "TEST_OCC_USER", station_id: "101") }
      let(:oai_user) { create(:user, css_id: "TEST_OAI_USER", station_id: "101") }

      context "the button is not shown for non occ/oai user" do
        before do
          BvaIntake.singleton.add_user(non_occoai_user)
          User.authenticate!(user: non_occoai_user)
        end
        it "the 'CAVC Dashboard' button is not visible on the page" do
          reload_case_detail_page cavc_appeal.external_id

          expect(page).to_not have_content(COPY::CAVC_DASHBOARD_BUTTON_TEXT)
        end
      end

      context "the button is shown for OCC user" do
        before do
          OccTeam.singleton.add_user(occ_user)
          User.authenticate!(user: occ_user)
        end
        it "the 'CAVC Dashboard' button is visible on the page" do
          reload_case_detail_page cavc_appeal.external_id

          expect(page).to have_content(COPY::CAVC_DASHBOARD_BUTTON_TEXT)
        end
      end

      context "the button is shown for OAI user" do
        before do
          OaiTeam.singleton.add_user(oai_user)
          User.authenticate!(user: oai_user)
        end
        it "the 'CAVC Dashboard' button is visible on the page" do
          reload_case_detail_page cavc_appeal.external_id

          expect(page).to have_content(COPY::CAVC_DASHBOARD_BUTTON_TEXT)
        end
      end
    end

    describe "MST and PACT issues" do
      let!(:mst_appeal) do
        create(
          :appeal,
          number_of_claimants: 1,
          request_issues: [
            create(
              :request_issue,
              benefit_type: "compensation",
              mst_status: true,
              pact_status: false,
              nonrating_issue_description: "description here",
              notes: "issue notes here"
            )
          ]
        )
      end
      let!(:pact_appeal) do
        create(
          :appeal,
          number_of_claimants: 1,
          request_issues: [
            create(
              :request_issue,
              benefit_type: "compensation",
              mst_status: false,
              pact_status: true,
              nonrating_issue_description: "description here",
              notes: "issue notes here"
            )
          ]
        )
      end

      let(:intake_user) { create(:user, css_id: "BVA_INTAKE_USER", station_id: "101") }

      context "when there is a pact issue prechecked" do
        before do
          FeatureToggle.enable!(:mst_identification)
          FeatureToggle.enable!(:pact_identification)
          BvaIntake.singleton.add_user(intake_user)
          User.authenticate!(user: intake_user)
        end

        after do
          FeatureToggle.disable!(:mst_identification)
          FeatureToggle.disable!(:pact_identification)
        end

        it "the page shows the Special Issues: PACT Badge" do
          visit "/queue/appeals/#{pact_appeal.external_id}"
          page.find("a", text: "refresh the page").click if page.has_text?("Unable to load this case")
          expect(page).to have_content("Special Issues: PACT")
        end

        it "the page does not show the Special Issues: MST Badge" do
          visit "/queue/appeals/#{pact_appeal.external_id}"
          page.find("a", text: "refresh the page").click if page.has_text?("Unable to load this case")
          expect(page).to_not have_content("Special Issues: MST")
        end
      end

      context "when there is an mst issue prechecked" do
        before do
          BvaIntake.singleton.add_user(intake_user)
          User.authenticate!(user: intake_user)
          FeatureToggle.enable!(:mst_identification)
          FeatureToggle.enable!(:pact_identification)
        end

        after do
          FeatureToggle.disable!(:mst_identification)
          FeatureToggle.disable!(:pact_identification)
        end

        it "the page shows the Special Issues: MST Badge" do
          visit "/queue/appeals/#{mst_appeal.external_id}"
          page.find("a", text: "refresh the page").click if page.has_text?("Unable to load this case")
          expect(page).to have_content("Special Issues: MST")
        end

        it "the page does not show the Special Issues: PACT Badge" do
          visit "/queue/appeals/#{mst_appeal.external_id}"
          page.find("a", text: "refresh the page").click if page.has_text?("Unable to load this case")
          expect(page).to_not have_content("Special Issues: PACT")
        end
      end
    end
  end

  describe "task snapshot" do
    context "when the only task is a TrackVeteranTask" do
      let(:root_task) { create(:root_task) }
      let(:appeal) { root_task.appeal }
      let(:tracking_task) { create(:track_veteran_task, parent: root_task) }

      it "should not show the tracking task in task snapshot" do
        visit("/queue/appeals/#{tracking_task.appeal.uuid}")
        expect(page).to have_content(COPY::TASK_SNAPSHOT_NO_ACTIVE_LABEL)
      end
    end

    context "when the only task is an IHP task" do
      let(:ihp_task) { create(:informal_hearing_presentation_task) }

      it "should show the label for the IHP task" do
        visit("/queue/appeals/#{ihp_task.appeal.uuid}")
        expect(page).to have_content(COPY::IHP_TASK_LABEL)
      end
    end
  end

  describe "AppealWithdrawalMailTask snapshot" do
    context "when child AppealWithdrawalMailTask is cancelled " do
      let!(:appeal) { create(:appeal) }
      let(:root_task) { create(:root_task, appeal: appeal) }

      let!(:appeal_withdrawal_mail_task) do
        create(
          :appeal_withdrawal_mail_task,
          appeal: appeal,
          instructions: ["cancelled"]
        )
      end

      let!(:appeal_withdrawal_bva_task) do
        create(
          :appeal_withdrawal_bva_task,
          appeal: appeal,
          parent: appeal_withdrawal_mail_task,
          instructions: ["cancelled"]
        )
      end

      let(:user) { create(:user) }

      before do
        CaseReview.singleton.add_user(user)
        User.authenticate!(user: user)
      end

      it "displays AppealWithdrawalMailTask in case timeline" do
        visit("/queue/appeals/#{appeal.uuid}")

        prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
        text = Constants.TASK_ACTIONS.CANCEL_TASK.label
        click_dropdown(prompt: prompt, text: text)
        fill_in "taskInstructions", with: "Cancelling task"
        click_button("Submit")

        expect(page).to have_content(format(COPY::CANCEL_TASK_CONFIRMATION, appeal.veteran_full_name))
        expect(page.current_path).to eq("/queue")

        click_on "Search"
        fill_in "searchBarEmptyList", with: appeal.veteran_file_number
        click_on "Search"
        click_on appeal.docket_number

        new_tasks = appeal_withdrawal_mail_task.reload.children
        expect(new_tasks.length).to eq(1)

        new_task = new_tasks.first
        expect(new_task.status).to eq Constants.TASK_STATUSES.cancelled
        expect(appeal_withdrawal_bva_task.assigned_to).to eq(CaseReview.singleton)
        expect(appeal_withdrawal_bva_task.parent.assigned_to).to eq(MailTeam.singleton)
      end
    end
  end

  describe "Case details page access control" do
    let(:queue_home_path) { "/queue" }
    let(:case_details_page_path) { "/queue/appeals/#{appeal.external_id}" }
    let(:veteran) { create(:veteran) }
    let(:higher_level_review) do
      create(:higher_level_review,
             :with_end_product_establishment,
             veteran_file_number: veteran.file_number)
    end

    let(:supplemental_claim) do
      create(:supplemental_claim,
             :with_end_product_establishment,
             veteran_file_number: veteran.file_number)
    end
    let(:user) { create(:intake_user) }

    context "when the current user does not have high enough BGS sensitivity level" do
      before do
        allow_any_instance_of(BGSService).to receive(:can_access?).and_return(false)
      end

      context "when the appeal is a legacy appeal" do
        let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
        let!(:veteran) { create(:veteran, file_number: appeal.sanitized_vbms_id) }

        # Assign a task to the current user so that a row appears on the queue page.
        let!(:task) { create(:ama_attorney_task, appeal: appeal, assigned_to: attorney_user) }

        context "when we navigate directly to the case details page" do
          it "displays a loading failed message on the case details page" do
            visit(case_details_page_path)
            expect(page).to have_content(COPY::ACCESS_DENIED_TITLE)
            expect(page).to have_current_path(case_details_page_path)
          end
        end

        context "when we click into the case details page from the queue table view" do
          it "displays a loading failed message on the case details page" do
            visit(queue_home_path)
            click_on("#{appeal.veteran_full_name} (#{appeal.veteran_file_number})")
            expect(page).to have_content(COPY::ACCESS_DENIED_TITLE)
            expect(page).to have_current_path(case_details_page_path)
          end
        end
      end
    end

    context "when the current user has high enough BGS sensitivity level" do
      before do
        allow_any_instance_of(BGSService).to receive(:can_access?).and_return(true)
      end

      context "when the appeal is a legacy appeal" do
        let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

        # Assign a task to the current user so that a row appears on the queue page.
        let!(:task) { create(:ama_attorney_task, appeal: appeal, assigned_to: attorney_user) }

        context "when we navigate directly to the case details page" do
          it "displays a loading failed message on the case details page" do
            visit(case_details_page_path)
            expect(page).to_not have_content(COPY::CASE_DETAILS_LOADING_FAILURE_TITLE)
            # The presence of the task snapshot element indicates that the case details page loaded.
            expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
            expect(page).to have_current_path(case_details_page_path)
          end
        end

        context "when we click into the case details page from the queue table view" do
          it "displays a loading failed message on the case details page" do
            visit(queue_home_path)
            click_on("#{appeal.veteran_full_name} (#{appeal.veteran_file_number})")
            expect(page).to_not have_content(COPY::CASE_DETAILS_LOADING_FAILURE_TITLE)
            # The presence of the task snapshot element indicates that the case details page loaded.
            expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
            expect(page).to have_current_path(case_details_page_path)
          end
        end
      end
    end

    context "when the current user does not have sensitivity level for Veteran file" do
      before do
        User.authenticate!(user: user)
        Fakes::BGSService.mark_veteran_not_accessible(higher_level_review.veteran_file_number)
        Fakes::BGSService.mark_veteran_not_accessible(supplemental_claim.veteran_file_number)
      end

      context "when case is higher level review" do
        it "renders 403 error page" do
          visit "/higher_level_reviews/#{higher_level_review.uuid}/edit"
          expect(page).to have_content(COPY::VETERAN_NOT_ACCESSIBLE_ERROR_TITLE)
          expect(page).to have_content(COPY::VETERAN_NOT_ACCESSIBLE_ERROR_DETAIL)
        end
      end

      context "when case is supplemental claim" do
        it "renders 403 error page" do
          visit "/supplemental_claims/#{supplemental_claim.uuid}/edit"
          expect(page).to have_content(COPY::VETERAN_NOT_ACCESSIBLE_ERROR_TITLE)
          expect(page).to have_content(COPY::VETERAN_NOT_ACCESSIBLE_ERROR_DETAIL)
        end
      end
    end
  end

  describe "POA/VSO restricted visibility" do
    let(:appeal) { create(:appeal) }

    RSpec.shared_context("with restrict_poa_visibility feature toggle") do
      before { FeatureToggle.enable!(:restrict_poa_visibility) }
      after { FeatureToggle.disable!(:restrict_poa_visibility) }
    end

    RSpec.shared_examples("access Case Details") do
      it "should view Case Details page" do
        visit "/queue/appeals/#{appeal.uuid}"
      end
    end

    RSpec.shared_examples("vso restricted") do
      it "has VSO visibility alert" do
        visit "/queue/appeals/#{appeal.uuid}"

        expect(page).to have_content(COPY::CASE_DETAILS_VSO_VISIBILITY_ALERT_TITLE)
        expect(page).to have_content(COPY::CASE_DETAILS_VSO_VISIBILITY_ALERT_MESSAGE)
      end
    end

    RSpec.shared_examples("vso unrestricted") do
      it "does not have VSO visibility alert" do
        visit "/queue/appeals/#{appeal.uuid}"

        expect(page).to_not have_content(COPY::CASE_DETAILS_VSO_VISIBILITY_ALERT_TITLE)
        expect(page).to_not have_content(COPY::CASE_DETAILS_VSO_VISIBILITY_ALERT_MESSAGE)
      end
    end

    context "as vso user" do
      let(:user) { create(:user, :vso_role) }

      before do
        User.authenticate!(user: user)
      end

      context "with feature toggle" do
        include_context "with restrict_poa_visibility feature toggle"

        it_should_behave_like "vso restricted"
      end

      context "without feature toggle" do
        it_should_behave_like "vso unrestricted"
      end
    end

    context "as non-vso user" do
      let(:user) { create(:default_user) }

      before do
        User.authenticate!(user: user)
      end

      context "with feature toggle" do
        include_context "with restrict_poa_visibility feature toggle"

        it_should_behave_like "vso unrestricted"
      end

      context "without feature toggle" do
        it_should_behave_like "vso unrestricted"
      end
    end
  end

  shared_examples "when vso_virtual_opt_in FeatureToggle is disabled" do
    before { FeatureToggle.disable!(:vso_virtual_opt_in) }
    after { FeatureToggle.enable!(:vso_virtual_opt_in) }

    it "the Hearings section does not appear despite
      there being an unscheduled hearing associated with the appeal" do
      visit "/queue/appeals/#{schedule_hearing_task.appeal.uuid}"

      expect(page.has_no_content?("Hearings")).to eq(true)
      expect(page.has_no_content?("Unscheduled hearing")).to eq(true)
      expect(page.has_no_content?(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)).to eq(true)
    end

    context "whenever there is a scheduled hearing" do
      let!(:hearing_day_close) do
        create(:hearing_day, :video, scheduled_for: 7.days.from_now, regional_office: "RO70")
      end

      let!(:hearing_day_far) do
        create(:hearing_day, :video, scheduled_for: 30.days.from_now, regional_office: "RO70")
      end

      let!(:hearing_day_past) do
        create(:hearing_day, :video, scheduled_for: 30.days.before, regional_office: "RO70")
      end

      let!(:hearing_within_10_days) { create(:hearing, hearing_day: hearing_day_close) }
      let!(:hearing_beyond_10_days) { create(:hearing, hearing_day: hearing_day_far) }
      let!(:hearing_in_past) { create(:hearing, hearing_day: hearing_day_past) }

      it "when the hearing 10+ days out the hearings details link is omitted" do
        visit "/queue/appeals/#{hearing_beyond_10_days.appeal.uuid}"

        expect(page.has_content?("Hearings")).to eq(true)
        expect(page.has_no_content?(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)).to eq(true)
        expect(page.has_no_content?(COPY::CASE_DETAILS_HEARING_DETAILS_LINK_COPY)).to eq(true)
      end

      it "when the hearing is <10 days out the hearings details link and notification banner are omitted" do
        visit "/queue/appeals/#{hearing_within_10_days.appeal.uuid}"

        expect(page.has_content?("Hearings")).to eq(true)
        expect(page.has_no_content?(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)).to eq(true)
        expect(page.has_no_content?(COPY::CASE_DETAILS_HEARING_DETAILS_LINK_COPY)).to eq(true)
        expect(page.has_no_content?(COPY::VSO_UNABLE_TO_CONVERT_TO_VIRTUAL_TEXT)).to eq(true)
      end

      it "when the hearing is in the past link and notification banner are omitted" do
        visit "/queue/appeals/#{hearing_in_past.appeal.uuid}"

        expect(page.has_content?("Hearings")).to eq(true)
        expect(page.has_no_content?(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)).to eq(true)
        expect(page.has_no_content?(COPY::CASE_DETAILS_HEARING_DETAILS_LINK_COPY)).to eq(true)
        expect(page.has_no_content?(COPY::VSO_UNABLE_TO_CONVERT_TO_VIRTUAL_TEXT)).to eq(true)
      end
    end
  end

  # National VSO Test
  context "when updating a hearing as a VSO user to virtual hearing" do
    let!(:vso) { create(:vso) }
    let!(:vso_user) { create(:user, :vso_role) }
    let!(:schedule_hearing_task) { create(:schedule_hearing_task, assigned_to: vso) }

    before do
      vso.add_user(vso_user)
      User.authenticate!(user: vso_user)
    end

    it "should not display a dropdown menu for VSO user" do
      step "go to the correct screen" do
        visit "/queue/appeals/#{schedule_hearing_task.appeal.uuid}"
        expect(page.has_no_content?("Select an action")).to eq(true)
      end
    end

    it_behaves_like "when vso_virtual_opt_in FeatureToggle is disabled"
  end

  # Field VSO Test
  context "when updating a hearing as a VSO user to virtual hearing" do
    let!(:field_vso) { create(:field_vso) }
    let!(:field_vso_user) { create(:user, :vso_role) }
    let!(:schedule_hearing_task) { create(:schedule_hearing_task, assigned_to: field_vso) }

    before do
      field_vso.add_user(field_vso_user)
      User.authenticate!(user: field_vso_user)
    end

    it "should not display a dropdown menu for VSO user" do
      step "go to the correct screen" do
        visit "/queue/appeals/#{schedule_hearing_task.appeal.uuid}"
        expect(page.has_no_content?("Select an action")).to eq(true)
      end
    end

    it_behaves_like "when vso_virtual_opt_in FeatureToggle is disabled"
  end

  # Private Bar Test
  context "when updating a hearing as a Private_Bar user to virtual hearing" do
    let!(:private_bar) { create(:private_bar) }
    let!(:private_bar_user) { create(:user, :vso_role) }
    let!(:schedule_hearing_task) { create(:schedule_hearing_task, assigned_to: private_bar) }

    before do
      private_bar.add_user(private_bar_user)
      User.authenticate!(user: private_bar_user)
    end

    it "should not display a dropdown menu for Private_Bar user" do
      step "go to the correct screen" do
        visit "/queue/appeals/#{schedule_hearing_task.appeal.uuid}"
        expect(page.has_no_content?("Select an action")).to eq(true)
      end
    end

    it_behaves_like "when vso_virtual_opt_in FeatureToggle is disabled"
  end

  context "when accessing the case details page as a VSO user without an email" do
    before do
      Timecop.return
      FeatureToggle.enable!(:vso_virtual_opt_in)
      vso_org.add_user(vso_user_no_email)
      User.authenticate!(user: vso_user_no_email)
    end

    after do
      Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
      FeatureToggle.disable!(:vso_virtual_opt_in)
    end

    let!(:vso_org) { create(:vso) }
    let!(:vso_user_no_email) { create(:user, :vso_role, email: nil) }
    let!(:schedule_hearing_task) { create(:schedule_hearing_task, assigned_to: vso_org) }

    subject do
      page.has_content?("Contact the Hearing Coordinator") && page.has_no_content?(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)
    end

    context "whenever there is an unscheduled hearing" do
      it "the conversion link is absent and a notification is displayed" do
        visit "/queue/appeals/#{schedule_hearing_task.appeal.uuid}"

        is_expected.to be true
      end
    end

    context "whenever there is a scheduled hearing within 10 days" do
      let!(:hearing) do
        create(:hearing,
               hearing_day:
                create(:hearing_day,
                       :video,
                       scheduled_for: 5.days.from_now,
                       regional_office: "RO11"))
      end

      it "the conversion link is absent and a notification is displayed" do
        visit "/queue/appeals/#{hearing.appeal.uuid}"

        expect(page.has_content?("Contact the Hearing Coordinator")).to eq true
        expect(page.has_content?(COPY::VSO_UNABLE_TO_CONVERT_TO_VIRTUAL_TEXT)).to eq true
        expect(page.has_no_content?(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)).to eq true
      end
    end

    context "whenever there is a scheduled hearing more than 10 days away" do
      let!(:hearing) do
        create(:hearing,
               hearing_day: create(
                 :hearing_day,
                 :video,
                 scheduled_for: 30.days.from_now,
                 regional_office: "RO13"
               ))
      end

      it "the conversion link is absent and a notification is displayed" do
        visit "/queue/appeals/#{hearing.appeal.uuid}"

        is_expected.to be true
      end
    end

    context "whenever there is a hearing scheduled in the past" do
      let!(:hearing) do
        create(:hearing,
               hearing_day: create(
                 :hearing_day,
                 :video,
                 scheduled_for: 30.days.before,
                 regional_office: "RO14"
               ))
      end

      it "no notifcation banner appears" do
        expect(page.has_no_content?(COPY::VSO_UNABLE_TO_CONVERT_TO_VIRTUAL_TEXT)).to eq true
        expect(page.has_no_content?("Contact the Hearing Coordinator")).to eq true
        expect(page.has_no_content?(COPY::VSO_CONVERT_TO_VIRTUAL_TEXT)).to eq true
      end
    end
  end

  describe "case title details" do
    shared_examples "show hearing request type" do
      it "displays hearing request type" do
        id = appeal.is_a?(Appeal) ? appeal.uuid : appeal.vacols_id

        visit("/queue/appeals/#{id}")

        expect(page).to have_content(COPY::TASK_SNAPSHOT_ABOUT_BOX_HEARING_REQUEST_TYPE_LABEL.upcase)
        expect(page).to have_content(appeal.readable_current_hearing_request_type)
      end
    end

    context "ama appeal" do
      context "hearing docket" do
        let!(:appeal) do
          create(:appeal, :hearing_docket, closest_regional_office: "C")
        end

        include_examples "show hearing request type"
      end
    end

    context "legacy appeal" do
      context "hearing docket" do
        let!(:appeal) do
          create(
            :legacy_appeal,
            vacols_case: create(
              :case,
              :travel_board_hearing
            )
          )
        end

        include_examples "show hearing request type"
      end
    end
  end

  describe "Unscheduled hearing notes" do
    let!(:current_user) do
      user = create(:user, css_id: "BVASYELLOW", roles: ["Build HearSched"])
      User.authenticate!(user: user)
    end
    let(:fill_in_notes) { "Fill in notes" }

    before do
      HearingsManagement.singleton.add_user(current_user)
    end

    shared_examples "edit unscheduled notes" do
      it "edits unscheduled successully" do
        id = appeal.external_id

        visit("/queue/appeals/#{id}")

        within("div#hearing-details") do
          expect(page).to have_content(COPY::UNSCHEDULED_HEARING_TITLE)
          expect(page).to have_content("Type: #{appeal.readable_current_hearing_request_type}")
          click_button("Edit", exact: true)
          fill_in "Notes", with: fill_in_notes
          click_button("Save", exact: true)
          expect(page).to have_content(fill_in_notes)
          expect(page).to have_content("Last updated by BVASYELLOW on #{Time.zone.now.strftime('%m/%d/%Y')}")
        end

        expect(page).to have_content(
          COPY::SAVE_UNSCHEDULED_NOTES_SUCCESS_MESSAGE % veteran_name
        )
      end
    end

    context "ama appeal" do
      let!(:appeal) do
        create(:appeal, :hearing_docket, closest_regional_office: "C")
      end
      let(:veteran_name) { appeal.veteran.name }
      let!(:schedule_hearing_task) do
        create(:schedule_hearing_task, appeal: appeal, assigned_to: current_user)
      end

      include_examples "edit unscheduled notes"
    end

    context "legacy appeal" do
      let!(:appeal) do
        create(
          :legacy_appeal,
          vacols_case: create(
            :case,
            :travel_board_hearing
          )
        )
      end
      let(:veteran_name) { appeal.veteran_full_name }
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal) }

      include_examples "edit unscheduled notes"
    end
  end

  describe "VSO access to the veteran's Case Details page where there's a PowerOfAttorneyDenied error" do
    let(:veteran) { create(:veteran) }
    let(:user) { create(:default_user, roles: ["VSO"]) }
    let(:vso) { create(:vso) }
    let(:appeal) { create(:appeal) }
    let(:root_task) { create(:root_task, appeal: appeal) }
    let!(:poa) do
      create(
        :bgs_power_of_attorney,
        :with_name_cached,
        appeal: appeal,
        poa_participant_id: vso.participant_id
      )
    end

    before do
      User.authenticate!(user: user)
      vso.add_user(user)
      allow_any_instance_of(Appeal).to receive(:representatives).and_return([vso])
      allow_any_instance_of(Representative).to receive(:user_has_access?).and_return(true)
      allow_any_instance_of(Veteran).to receive(:bgs).and_return(bgs)
      allow(bgs).to receive(:fetch_veteran_info).and_call_original
    end

    let(:bgs) { Fakes::BGSService.new }
    msg = "(Power of Attorney of Folder is none. Access to this record is denied.)"

    context "when the VSO User should have access" do
      let!(:vso_task) do
        create(:track_veteran_task, :in_progress, parent: root_task, assigned_to: vso, appeal: root_task.appeal)
      end

      context "rescue POA Folder denied errors from BGS for VSOs" do
        it "case details displays error message" do
          visit("/queue/appeals/#{appeal.uuid}")
          allow(bgs).to receive(:fetch_veteran_info).and_raise(BGS::PowerOfAttorneyFolderDenied.new(msg))
          # revisit the queue page and make sure it loads
          expect(appeal.accessible?).to be_truthy
          visit("/queue/appeals/#{appeal.uuid}")
          expect(page).to have_content(appeal.claimant.address_line_1)
        end
      end

      context "check to see if VSO should have access to appeal anyway" do
        it "should display case details" do
          expect(appeal.accessible?).to be_truthy
          visit("/queue/appeals/#{appeal.uuid}")
          expect(page).to have_content(appeal.claimant.address_line_1)
        end
      end
    end

    context "when the VSO User should have not access" do
      # no vso task
      before do
        allow_any_instance_of(BGSService).to receive(:can_access?).and_return(false)
      end
      context "the Case Details page displays error message" do
        it "should continue to not display details" do
          visit("/queue/appeals/#{appeal.uuid}")
          allow(bgs).to receive(:fetch_veteran_info).and_raise(BGS::PowerOfAttorneyFolderDenied.new(msg))
          # revist the queue page and make sure it still errors
          expect(appeal.accessible?).to be_falsey
          visit("/queue/appeals/#{appeal.uuid}")
          expect(page).to have_content("Additional access needed")
        end
      end
    end
  end
end
