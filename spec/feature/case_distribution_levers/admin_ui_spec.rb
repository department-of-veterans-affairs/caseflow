# frozen_string_literal: true

RSpec.feature "Admin UI" do
  # TODO: break this out if possible
  before { Seeds::CaseDistributionLevers.new.seed! }

  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:disabled_lever_list) do
    [
      Constants.DISTRIBUTION.cavc_aod_affinity_days,
      Constants.DISTRIBUTION.cavc_affinity_days,
      Constants.DISTRIBUTION.aoj_affinity_days,
      Constants.DISTRIBUTION.aoj_aod_affinity_days,
      Constants.DISTRIBUTION.aoj_cavc_affinity_days
    ]
  end

  let(:enabled_lever_list) do
    [
      Constants.DISTRIBUTION.ama_hearing_case_affinity_days,
      Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days
    ]
  end

  let(:ama_hearings) { Constants.DISTRIBUTION.ama_hearing_start_distribution_prior_to_goals }
  let(:ama_direct_reviews) { Constants.DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals }
  let(:ama_evidence_submissions) { Constants.DISTRIBUTION.ama_evidence_submission_start_distribution_prior_to_goals }

  let(:alternate_batch_size) { Constants.DISTRIBUTION.alternative_batch_size }
  let(:batch_size_per_attorney) { Constants.DISTRIBUTION.batch_size_per_attorney }
  let(:request_more_cases_minimum) { Constants.DISTRIBUTION.request_more_cases_minimum }

  let(:ama_direct_reviews_lever) { CaseDistributionLever.find_by_item(ama_direct_reviews) }
  let(:alternate_batch_size_lever) { CaseDistributionLever.find_by_item(alternate_batch_size) }


  let(:maximum_direct_review_proportion) { Constants.DISTRIBUTION.maximum_direct_review_proportion }
  let(:minimum_legacy_proportion) { Constants.DISTRIBUTION.minimum_legacy_proportion }
  let(:nod_adjustment) { Constants.DISTRIBUTION.nod_adjustment }
  let(:bust_backlog) { Constants.DISTRIBUTION.bust_backlog }

  context "user is in Case Distro Algorithm Control organization but not an admin" do
    let!(:audit_lever_entry_1) do
      create(:case_distribution_audit_lever_entry,
             case_distribution_lever: ama_direct_reviews_lever,
             previous_value: 10,
             update_value: 15,
             created_at: 5.days.ago)
    end
    let!(:audit_lever_entry_2) do
      create(:case_distribution_audit_lever_entry,
             case_distribution_lever: alternate_batch_size_lever,
             previous_value: 7,
             update_value: 6,
             created_at: 4.days.ago)
    end
    let!(:audit_lever_entry_3) do
      Timecop.travel(3.days.ago) do
        create(:case_distribution_audit_lever_entry,
               case_distribution_lever: ama_direct_reviews_lever,
               previous_value: 15,
               update_value: 5)
        create(:case_distribution_audit_lever_entry,
               case_distribution_lever: alternate_batch_size_lever,
               previous_value: 2,
               update_value: 4)
      end
    end

    scenario "the lever control page operates correctly", :aggregate_failures do
      step "page renders" do
        visit "case-distribution-controls"
        confirm_page_and_section_loaded

        disabled_lever_list.each do |item|
          expect(find("#lever-wrapper-#{item}")).to match_css(".lever-disabled")
          expect(find("#affinity-day-label-for-#{item}")).to match_css(".lever-disabled")
        end

        enabled_lever_list.each do |item|
          expect(find("#lever-wrapper-#{item}")).not_to match_css(".lever-disabled")
          expect(find("#affinity-day-label-for-#{item}")).not_to match_css(".lever-disabled")
        end

        expect(find("##{ama_hearings}-lever-value > span")["data-disabled-in-ui"]).to eq("false")
        expect(find("##{ama_direct_reviews}-lever-value > span")["data-disabled-in-ui"]).to eq("false")
        expect(find("##{ama_evidence_submissions}-lever-value > span")["data-disabled-in-ui"]).to eq("false")

        expect(find("##{ama_hearings}-lever-toggle > div > span")["data-disabled-in-ui"]).to eq("false")
        expect(find("##{ama_direct_reviews}-lever-toggle > div > span")["data-disabled-in-ui"]).to eq("false")
        expect(find("##{ama_evidence_submissions}-lever-toggle > div > span")["data-disabled-in-ui"]).to eq("false")

        expect(find("##{alternate_batch_size} > label")).to match_css(".lever-active")
        expect(find("##{batch_size_per_attorney} > label")).to match_css(".lever-active")
        expect(find("##{request_more_cases_minimum} > label")).to match_css(".lever-active")
      end

      step "lever history displays correctly" do
        expect(find("#lever-history-table-row-0")).to have_content(current_user.css_id)
        expect(find("#lever-history-table-row-0")).to have_content(alternate_batch_size_lever.title)
        expect(find("#lever-history-table-row-0")).to have_content("2 #{alternate_batch_size_lever.unit}")
        expect(find("#lever-history-table-row-0")).to have_content("4 #{alternate_batch_size_lever.unit}")
        expect(find("#lever-history-table-row-0")).to have_content(ama_direct_reviews_lever.title)
        expect(find("#lever-history-table-row-0")).to have_content("15 #{ama_direct_reviews_lever.unit}")
        expect(find("#lever-history-table-row-0")).to have_content("5 #{ama_direct_reviews_lever.unit}")

        expect(find("#lever-history-table-row-1")).to have_content(current_user.css_id)
        expect(find("#lever-history-table-row-1")).to have_content(alternate_batch_size_lever.title)
        expect(find("#lever-history-table-row-1")).to have_content("7 #{alternate_batch_size_lever.unit}")
        expect(find("#lever-history-table-row-1")).to have_content("6 #{alternate_batch_size_lever.unit}")

        expect(find("#lever-history-table-row-2")).to have_content(current_user.css_id)
        expect(find("#lever-history-table-row-2")).to have_content(ama_direct_reviews_lever.title)
        expect(find("#lever-history-table-row-2")).to have_content("10 #{ama_direct_reviews_lever.unit}")
        expect(find("#lever-history-table-row-2")).to have_content("15 #{ama_direct_reviews_lever.unit}")
      end
    end
  end

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end
  end

  # rubocop:disable Metrics/AbcSize
  def confirm_page_and_section_loaded
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_AFFINITY_DAYS_H2_TITLE)
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_DOCKET_TIME_GOALS_SECTION_TITLE)
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_BATCH_SIZE_H2_TITLE)
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_HISTORY_TITLE)
    expect(page).to have_content(COPY::CASE_DISTRIBUTION_HISTORY_DESCRIPTION)
    expect(page).to have_content(Constants.DISTRIBUTION.ama_hearing_case_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.cavc_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.cavc_aod_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.aoj_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.aoj_aod_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.aoj_cavc_affinity_days_title)
    expect(page).to have_content(Constants.DISTRIBUTION.ama_hearings_section_title)
    expect(page).to have_content(Constants.DISTRIBUTION.ama_direct_review_section_title)
    expect(page).to have_content(Constants.DISTRIBUTION.ama_evidence_submission_section_title)
    expect(page).to have_content(Constants.DISTRIBUTION.alternative_batch_size_title)
    expect(page).to have_content(Constants.DISTRIBUTION.batch_size_per_attorney_title)
    expect(page).to have_content(Constants.DISTRIBUTION.request_more_cases_minimum_title)

    expect(find("##{maximum_direct_review_proportion}-description")).to match_css(".description-styling")
    expect(find("##{maximum_direct_review_proportion}-product")).to match_css(".value-styling")

    expect(find("##{minimum_legacy_proportion}-description")).to match_css(".description-styling")
    expect(find("##{minimum_legacy_proportion}-product")).to match_css(".value-styling")

    expect(find("##{nod_adjustment}-description")).to match_css(".description-styling")
    expect(find("##{nod_adjustment}-product")).to match_css(".value-styling")

    expect(find("##{bust_backlog}-description")).to match_css(".description-styling")
    expect(find("##{bust_backlog}-product")).to match_css(".value-styling")

    expect(page).not_to have_button("Cancel")
    expect(page).not_to have_button("Save")
  end
  # rubocop:enable Metrics/AbcSize
end
