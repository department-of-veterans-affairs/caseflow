# frozen_string_literal: true

feature "NonComp Dispositions Task Page", :postgres do
  include IntakeHelpers

  def fill_in_disposition(num, disposition, description = nil)
    if description
      fill_in "description-issue-#{num}", with: description
    end

    fill_in "disposition-issue-#{num}", with: disposition
    find("#disposition-issue-#{num}").send_keys :enter
  end

  def find_dropdown_num_by_disposition(disposition)
    nodes = find_all(".cf-form-dropdown")

    nodes.each do |node|
      if node.text.match?(/#{disposition}/)
        return nodes.index(node)
      end
    end
  end

  def find_disabled_disposition(disposition, description = nil)
    num = find_dropdown_num_by_disposition(disposition)
    expect(page).to have_field(type: "textarea", with: description, disabled: true)

    scroll_to(find(".dropdown-disposition-issue-#{num}"))

    within(".dropdown-disposition-issue-#{num}") do
      expect(find(".cf-select__single-value", text: disposition)).to_not be_nil
    end
    expect(page).to have_css("[id='disposition-issue-#{num}'][readonly]", visible: false)
  end

  context "with an existing organization" do
    let!(:non_comp_org) { create(:business_line, name: "National Cemetery Administration", url: "nca") }

    let(:user) { create(:default_user) }

    let(:veteran) { create(:veteran) }

    let(:epe) { create(:end_product_establishment, veteran_file_number: veteran.file_number) }

    let(:decision_review) do
      create(
        :higher_level_review,
        end_product_establishments: [epe],
        veteran_file_number: veteran.file_number,
        benefit_type: non_comp_org.url,
        veteran_is_not_claimant: false,
        claimant_type: :veteran_claimant
      )
    end

    let!(:request_issues) do
      3.times do
        create(:request_issue,
               :nonrating,
               end_product_establishment: epe,
               veteran_participant_id: veteran.participant_id,
               decision_review: decision_review,
               benefit_type: decision_review.benefit_type)
      end
    end

    let!(:ineligible_request_issue) do
      create(:request_issue,
             :nonrating,
             :ineligible,
             nonrating_issue_description: "ineligible issue",
             end_product_establishment: epe,
             veteran_participant_id: veteran.participant_id,
             decision_review: decision_review,
             benefit_type: decision_review.benefit_type)
    end

    let!(:in_progress_task) do
      create(:higher_level_review_task, :in_progress, appeal: decision_review, assigned_to: non_comp_org)
    end

    let(:business_line_url) { "decision_reviews/nca" }
    let(:dispositions_url) { "#{business_line_url}/tasks/#{in_progress_task.id}" }
    let(:arbitrary_decision_date) { "01/01/2019" }

    let(:vet_id_column_value) { veteran.ssn }

    before do
      User.stub = user
      non_comp_org.add_user(user)
      setup_prior_claim_with_payee_code(decision_review, veteran, "00")
      FeatureToggle.enable!(:decision_review_queue_ssn_column)
      FeatureToggle.enable!(:poa_button_refresh)
    end

    after do
      FeatureToggle.disable!(:decision_review_queue_ssn_column)
      FeatureToggle.disable!(:poa_button_refresh)
    end

    context "decision_review is a Supplemental Claim" do
      let(:decision_review) do
        create(
          :supplemental_claim,
          end_product_establishments: [epe],
          veteran_file_number: veteran.file_number,
          benefit_type: non_comp_org.url,
          veteran_is_not_claimant: false,
          claimant_type: :veteran_claimant
        )
      end

      scenario "does not offer DTA Error as a disposition choice" do
        visit dispositions_url

        expect(page).to have_content("National Cemetery Administration")

        expect do
          click_dropdown name: "disposition-issue-1", text: "DTA Error", wait: 1
        end.to raise_error(Capybara::ElementNotFound)

        expect(page).to_not have_content("DTA Error")
      end
    end

    scenario "displays dispositions page" do
      visit dispositions_url

      within("header") do
        expect(page).to have_css("p", text: "National Cemetery Administration")
      end
      expect(page).to have_content("National Cemetery Administration")
      expect(page).to have_content("Decision")
      expect(page).to have_content(veteran.name)
      expect(page).to have_content(
        "Prior decision date: #{decision_review.request_issues[0].decision_date.strftime('%m/%d/%Y')}"
      )
      expect(page).to have_no_content(COPY::CASE_DETAILS_POA_SUBSTITUTE)
      expect(page).not_to have_button(COPY::REFRESH_POA)
      expect(page).to have_content(Constants.INTAKE_FORM_NAMES.higher_level_review)
    end

    scenario "cancel returns back to business line page" do
      visit dispositions_url

      click_on "Cancel"
      expect(page).to have_current_path("/#{business_line_url}", ignore_query: true)
    end

    context "the complete button enables only after a decision date and disposition are set" do
      before do
        visit dispositions_url
        FeatureToggle.enable!(:poa_button_refresh)
      end

      after { FeatureToggle.disable!(:poa_button_refresh) }

      scenario "neither disposition nor date is set" do
        expect(page).to have_button("Complete", disabled: true)
      end

      scenario "only date is set" do
        fill_in "decision-date", with: arbitrary_decision_date
        expect(page).to have_button("Complete", disabled: true)
      end

      scenario "only disposition is set" do
        fill_in_disposition(0, "Granted")
        fill_in_disposition(1, "DTA Error", "test description")
        fill_in_disposition(2, "Denied", "denied")

        expect(page).to have_button("Complete", disabled: true)
      end

      scenario "both disposition and date are set" do
        fill_in "decision-date", with: arbitrary_decision_date
        fill_in_disposition(0, "Granted")
        fill_in_disposition(1, "DTA Error", "test description")
        fill_in_disposition(2, "Denied", "denied")

        expect(page).to have_button("Complete", disabled: false)
      end
    end

    scenario "saves decision issues for eligible request issues" do
      visit dispositions_url
      expect(page).to have_button("Complete", disabled: true)
      expect(page).to have_link("Edit Issues")
      expect(page).to_not have_content("ineligible issue")

      # set description & disposition for each active request issue
      fill_in_disposition(0, "Granted")
      fill_in_disposition(1, "DTA Error", "test description")
      fill_in_disposition(2, "Denied", "denied")
      fill_in "decision-date", with: arbitrary_decision_date

      # save
      expect(page).to have_button("Complete", disabled: false)
      click_on "Complete"

      # should have success message
      expect(page).to have_content("Decision Completed")
      # should redirect to business line's completed tab
      expect(page.current_path).to eq "/#{business_line_url}"
      expect(page).to have_content(vet_id_column_value)

      # verify database updated
      dissues = decision_review.reload.decision_issues
      expect(dissues.length).to eq(3)
      expect(dissues.find_by(disposition: "Granted", description: nil)).to_not be_nil
      expect(dissues.find_by(disposition: "DTA Error", description: "test description")).to_not be_nil
      expect(dissues.find_by(disposition: "Denied", description: "denied")).to_not be_nil

      # verify that going to the completed task does not allow edits
      click_link veteran.name.to_s
      expect(page).to have_content("Review each issue and assign the appropriate dispositions")
      expect(page).to have_current_path("/#{dispositions_url}")
      expect(page).not_to have_button("Complete")
      expect(page).not_to have_link("Edit Issues")

      find_disabled_disposition("Granted")
      find_disabled_disposition("DTA Error", "test description")
      find_disabled_disposition("Denied", "denied")

      # decision date should be saved
      expect(page).to have_css("input[value='#{arbitrary_decision_date.to_date.strftime('%Y-%m-%d')}']")
    end

    context "when there is an error saving" do
      before do
        allow_any_instance_of(DecisionReviewTask).to receive(:complete_with_payload!).and_throw("Error!")
      end

      scenario "Shows an error when something goes wrong" do
        visit dispositions_url

        fill_in_disposition(0, "Granted")
        fill_in_disposition(1, "Granted", "test description")
        fill_in_disposition(2, "Denied", "denied")
        fill_in "decision-date", with: arbitrary_decision_date

        click_on "Complete"
        expect(page).to have_content("Something went wrong")
        expect(page).to have_current_path("/#{dispositions_url}")
      end
    end

    context "with user enabled for intake" do
      before do
        # allow user to have access to intake
        user.update(roles: user.roles << "Mail Intake")
        Functions.grant!("Mail Intake", users: [user.css_id])
      end

      scenario "goes back to intake" do
        visit dispositions_url
        expect(page).to have_link("Edit Issues", href: decision_review.reload.caseflow_only_edit_issues_url)
      end
    end
  end

  context "Decision Review Task Page for High level Claims" do
    before do
      User.stub = user
      vha_org.add_user(user)
      Timecop.travel(Time.zone.local(2023, 0o2, 0o1))
    end

    after do
      Timecop.return
      FeatureToggle.disable!(:poa_button_refresh)
    end

    let!(:vha_org) { VhaBusinessLine.singleton }
    let(:user) { create(:default_user) }
    let(:veteran) { create(:veteran) }
    let(:decision_date) { Time.zone.now + 10.days }

    let!(:in_progress_task) do
      create(:higher_level_review,
             :with_vha_issue,
             :with_end_product_establishment,
             :create_business_line,
             benefit_type: "vha",
             veteran: veteran,
             claimant_type: :veteran_claimant)
    end

    let(:poa_task) do
      create(:supplemental_claim_poa_task)
    end

    let(:business_line_url) { "decision_reviews/vha" }
    let(:dispositions_url) { "#{business_line_url}/tasks/#{in_progress_task.id}" }

    it "vha decision Review workflow" do
      step "submit button should be disabled and cancel returns back to business line" do
        visit dispositions_url
        expect(page).to have_button("Complete", disabled: true)
        click_on "Cancel"
        expect(page).to have_current_path("/#{business_line_url}", ignore_query: true)
      end

      step "completing a task should redirect to completed task tab" do
        visit dispositions_url
        fill_in "decision-date", with: decision_date.strftime("%m/%d/%Y")
        fill_in_disposition(0, "Granted", "granted")
        scroll_to(page, align: :bottom)
        expect(page).to have_button("Complete", disabled: false)
        click_button("Complete")
        expect(page).to have_current_path("/#{business_line_url}?tab=completed&page=1")
      end

      step "completed Decision review task should have specific decision date provided during completion" do
        visit dispositions_url
        expect(page).to have_selector("h1", text: "Veterans Health Administration")
        expect(page).to have_content(veteran.name)
        expect(page.find("textarea").disabled?).to be true

        disposition_dropdown = page.find("div.cf-select")
        expect(disposition_dropdown).to have_content("Granted")
        expect(disposition_dropdown).to have_css(".cf-select--is-disabled")
        expect(page).to have_text(COPY::DISPOSITION_DECISION_DATE_LABEL)
        expect(page.find_by_id("decision-date").value).to have_content(decision_date.strftime("%Y-%m-%d"))
      end
    end

    it "VHA Decision Review should have Power of Attorney Section" do
      visit dispositions_url

      expect(page).to have_selector("h1", text: "Veterans Health Administration")
      expect(page).to have_selector("h2", text: COPY::CASE_DETAILS_POA_SUBSTITUTE)
      expect(page).to have_text("Attorney: #{in_progress_task.representative_name}")
      expect(page).to have_text("Email Address: #{in_progress_task.representative_email_address}")

      expect(page).to have_text("Address")
      expect(page).to have_content(COPY::CASE_DETAILS_POA_EXPLAINER_VHA)
      full_address = in_progress_task.power_of_attorney.representative_address
      sliced_full_address = full_address.slice!(:country)
      sliced_full_address.each do |address|
        expect(page).to have_text(address[1])
      end

      expect(page).not_to have_button(COPY::REFRESH_POA)
    end

    scenario "When feature toggle is enabled Refresh button should be visible." do
      enable_feature_flag_and_redirect_to_disposition

      last_synced_date = in_progress_task.poa_last_synced_at.to_date.strftime("%m/%d/%Y")
      expect(page).to have_text("POA last refreshed on #{last_synced_date}")
      expect(page).to have_button(COPY::REFRESH_POA)
    end

    scenario "when cooldown time is greater than 0 it should return Alert message" do
      cooldown_period = 7
      instance_decision_reviews = allow_any_instance_of(DecisionReviewsController)
      instance_decision_reviews.to receive(:cooldown_period_remaining).and_return(cooldown_period)
      enable_feature_flag_and_redirect_to_disposition
      expect(page).to have_text(COPY::CASE_DETAILS_POA_SUBSTITUTE)
      expect(page).to have_button(COPY::REFRESH_POA)

      click_on COPY::REFRESH_POA
      expect(page).to have_text("Power of Attorney (POA) data comes from VBMS")
      expect(page).to have_text("Information is current at this time. Please try again in #{cooldown_period} minutes")
    end

    scenario "when cooldown time is 0, it should update POA" do
      allow_any_instance_of(DecisionReviewsController).to receive(:cooldown_period_remaining).and_return(0)
      enable_feature_flag_and_redirect_to_disposition
      expect(page).to have_content(COPY::REFRESH_POA)
      click_on COPY::REFRESH_POA
      expect(page).to have_text("Power of Attorney (POA) data comes from VBMS")
      expect(page).to have_content(COPY::POA_UPDATED_SUCCESSFULLY)
    end

    scenario "when POA record is blank, Refresh button should return not found message" do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids).and_return({})
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poa_by_file_number).and_return({})

      enable_feature_flag_and_redirect_to_disposition
      expect(page).to have_content(COPY::REFRESH_POA)
      click_on COPY::REFRESH_POA
      expect(page).to have_text(COPY::VHA_NO_POA)
      expect(page).to have_text(COPY::POA_SUCCESSFULLY_REFRESH_MESSAGE)
    end

    context "with no POA" do
      before do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids).and_return({})
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poa_by_file_number).and_return({})
      end
      it "should display the VHA-specific text" do
        visit dispositions_url
        expect(page).to have_content(COPY::CASE_DETAILS_NO_POA_VHA)
      end
    end

    context "with an unrecognized POA" do
      let(:poa) { in_progress_task.power_of_attorney }
      before do
        poa.update(representative_type: "Unrecognized representative")
      end
      it "should display the VHA-specific text" do
        visit dispositions_url
        expect(page).to have_content(COPY::CASE_DETAILS_UNRECOGNIZED_POA_VHA)
      end
    end

    context "with a not listed POA" do
      context "for a higher level review" do
        let(:decision_review) do
          create(
            :higher_level_review,
            veteran_file_number: veteran.file_number,
            benefit_type: vha_org.url,
            veteran_is_not_claimant: true,
            claimant_type: :other_claimant_not_listed
          )
        end
        let(:in_progress_task) do
          create(:higher_level_review_task, :in_progress, appeal: decision_review, assigned_to: vha_org)
        end
        let(:dispositions_url) { "#{business_line_url}/tasks/#{in_progress_task.id}" }

        it "should display the VHA-specific text" do
          visit dispositions_url
          expect(page).to have_content("Veterans Health Administration")
          expect(page).to have_content(COPY::CASE_DETAILS_NO_RECOGNIZED_POA_VHA)
        end
      end

      context "for supplemental claim" do
        let(:decision_review) do
          create(
            :supplemental_claim,
            veteran_file_number: veteran.file_number,
            benefit_type: vha_org.url,
            veteran_is_not_claimant: true,
            claimant_type: :other_claimant_not_listed
          )
        end
        let(:in_progress_task) do
          create(:supplemental_claim_task, :in_progress, appeal: decision_review, assigned_to: vha_org)
        end
        let(:dispositions_url) { "#{business_line_url}/tasks/#{in_progress_task.id}" }

        it "should display the VHA-specific text" do
          visit dispositions_url
          expect(page).to have_content("Veterans Health Administration")
          expect(page).to have_content(COPY::CASE_DETAILS_NO_RECOGNIZED_POA_VHA)
        end
      end
    end
  end

  def enable_feature_flag_and_redirect_to_disposition
    FeatureToggle.enable!(:poa_button_refresh)
    visit dispositions_url
  end
end
