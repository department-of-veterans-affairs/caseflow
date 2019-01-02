require "rails_helper"

RSpec.feature "Judge checkout flow" do
  let(:attorney_user) { FactoryBot.create(:default_user) }
  let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

  let(:judge_user) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }
  let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, sdomainid: judge_user.css_id) }

  context "given a valid ama appeal with single issue" do
    let!(:appeal) do
      FactoryBot.create(
        :appeal,
        number_of_claimants: 1,
        request_issues: FactoryBot.build_list(:request_issue, 1, description: "Tinnitus", disposition: "allowed")
      )
    end

    let(:root_task) { FactoryBot.create(:root_task) }
    let(:parent_task) do
      FactoryBot.create(
        :ama_judge_decision_review_task,
        :in_progress,
        assigned_to: judge_user,
        appeal: appeal,
        parent: root_task
      )
    end

    let(:child_task) do
      FactoryBot.create(
        :ama_attorney_task,
        :in_progress,
        assigned_to: attorney_user,
        assigned_by: judge_user,
        parent: parent_task,
        appeal: appeal
      )
    end

    before do
      child_task.mark_as_complete!
      User.authenticate!(user: judge_user)
    end

    scenario "starts dispatch checkout flow" do
      visit "/queue"
      click_on "(#{appeal.veteran_file_number})"

      click_dropdown(index: 0) do
        visible_options = page.find_all(".Select-option")
        expect(visible_options.length).to eq 1
        expect(visible_options.first.text).to eq COPY::JUDGE_CHECKOUT_DISPATCH_LABEL
      end

      # Special Issues screen
      click_on "Continue"
      # Request Issues screen
      click_on "Continue"
      expect(page).to have_content("Evaluate Decision")

      expect(page).to_not have_content("One Touch Initiative")

      find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
      text_to_click = "1 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['does_not_meet_expectations']}"
      find("label", text: text_to_click).click
      find("#issues_are_not_addressed", visible: false).sibling("label").click

      dummy_note = generate_words 5
      fill_in "additional-factors", with: dummy_note
      expect(page).to have_content(dummy_note[0..5])

      click_on "Continue"
      expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)
      case_review = JudgeCaseReview.find_by(task_id: parent_task.id)
      expect(case_review.attorney).to eq attorney_user
      expect(case_review.judge).to eq judge_user
      expect(case_review.complexity).to eq "easy"
      expect(case_review.quality).to eq "does_not_meet_expectations"
      expect(case_review.one_touch_initiative).to eq false
    end
  end

  context "given a valid legacy appeal with single issue" do
    let!(:appeal) do
      FactoryBot.create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: FactoryBot.create(
          :case,
          :assigned,
          user: judge_user,
          assigner: attorney_user,
          case_issues: [
            FactoryBot.create(:case_issue, :disposition_allowed),
            FactoryBot.create(:case_issue, :disposition_granted_by_aoj)
          ],
          work_product: work_product
        )
      )
    end

    before do
      FeatureToggle.enable!(:judge_case_review_checkout)

      User.authenticate!(user: judge_user)
    end

    after do
      FeatureToggle.disable!(:judge_case_review_checkout)
    end

    context "where work product is draft decision" do
      let(:work_product) { :draft_decision }

      scenario "starts dispatch checkout flow" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"

        click_dropdown(index: 0) do
          visible_options = page.find_all(".Select-option")
          expect(visible_options.length).to eq 1
          expect(visible_options.first.text).to eq COPY::JUDGE_CHECKOUT_DISPATCH_LABEL
        end

        # one issue is decided, excluded from checkout flow
        expect(appeal.issues.length).to eq 2
        expect(page.find_all(".issue-disposition-dropdown").length).to eq 1

        click_on "Continue"
        expect(page).to have_content("Evaluate Decision")

        expect(page).to have_content("One Touch Initiative")
        find("label", text: COPY::JUDGE_EVALUATE_DECISION_CASE_ONE_TOUCH_INITIATIVE_SUBHEAD).click

        find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
        text_to_click = "1 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['does_not_meet_expectations']}"
        find("label", text: text_to_click).click

        find("#issues_are_not_addressed", visible: false).sibling("label").click

        dummy_note = generate_words 5
        fill_in "additional-factors", with: dummy_note
        expect(page).to have_content(dummy_note[0..5])

        click_on "Continue"

        expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)

        expect(VACOLS::Decass.find(appeal.vacols_id).de1touch).to eq "Y"
      end
    end

    context "where work product is omo request" do
      let(:work_product) { :omo_request }

      scenario "completes assign to omo checkout flow" do
        visit "/queue/appeals/#{appeal.vacols_id}"

        click_dropdown(index: 0) do
          visible_options = page.find_all(".Select-option")
          expect(visible_options.length).to eq 1
          expect(visible_options.first.text).to eq COPY::JUDGE_CHECKOUT_OMO_LABEL
        end

        expect(page).to have_content("Evaluate Decision")

        radio_group_cls = "usa-fieldset-inputs cf-form-radio "
        case_complexity_opts = page.find_all(:xpath, "//fieldset[@class='#{radio_group_cls}'][1]//label")
        case_quality_opts = page.find_all(:xpath, "//fieldset[@class='#{radio_group_cls}'][2]//label")

        expect(case_quality_opts.first.text).to eq(
          "5 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['outstanding']}"
        )
        expect(case_quality_opts.last.text).to eq(
          "1 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['does_not_meet_expectations']}"
        )

        case_complexity_opts[0].click
        case_quality_opts[2].click
        # areas of improvement
        areas_of_improvement = page.find_all(
          :xpath, "//fieldset[@class='checkbox-wrapper-Identify areas for improvement cf-form-checkboxes']//label"
        )
        areas_of_improvement[0].double_click
        areas_of_improvement[5].double_click

        dummy_note = "lorem ipsum dolor sit amet"
        fill_in "additional-factors", with: dummy_note

        click_on "Continue"

        expect(page).to have_content(COPY::JUDGE_CHECKOUT_OMO_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)
        decass = VACOLS::Decass.find_by(defolder: appeal.vacols_id, deadtim: Time.zone.today)
        expect(decass.decomp).to eq(VacolsHelper.local_date_with_utc_timezone)
        expect(decass.deoq).to eq("3")
      end
    end
  end
end
