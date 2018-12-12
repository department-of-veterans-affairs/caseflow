require "rails_helper"

def click_dropdown(opt_idx, container = page)
  dropdown = container.find(".Select-control")
  dropdown.click
  yield if block_given?
  dropdown.sibling(".Select-menu-outer").find("div[id$='--option-#{opt_idx}']").click
end

def generate_text(length)
  charset = ("A".."Z").to_a.concat(("a".."z").to_a)
  Array.new(length) { charset.sample }.join
end

def generate_words(n_words)
  Array.new(n_words).map do
    word_length = [rand(12), 3].max
    generate_text(word_length)
  end.join(" ")
end

RSpec.feature "Case Assignment flows" do
  let(:attorney_user) { FactoryBot.create(:user) }
  let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

  let(:judge_user) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }
  let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, sdomainid: judge_user.css_id) }

  before do
    FeatureToggle.enable! :attorney_assignment_to_colocated
  end

  after do
    FeatureToggle.disable! :attorney_assignment_to_colocated
  end

  context "given a valid legacy appeal and an attorney user" do
    let!(:appeals) do
      [
        FactoryBot.create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: FactoryBot.create(
            :case,
            :assigned,
            user: attorney_user,
            case_issues: FactoryBot.create_list(:case_issue, 1)
          )
        ),
        FactoryBot.create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: FactoryBot.create(
            :case,
            :assigned,
            user: attorney_user,
            case_issues: FactoryBot.create_list(:case_issue, 1)
          )
        )
      ]
    end

    before do
      u = FactoryBot.create(:user)
      OrganizationsUser.add_user_to_organization(u, Colocated.singleton)

      User.authenticate!(user: attorney_user)
    end

    scenario "adds colocated task" do
      visit "/queue"
      click_on "#{appeals[0].veteran_full_name} (#{appeals[0].sanitized_vbms_id})"
      click_dropdown 2

      expect(page).to have_content("Submit admin action")

      opt_idx = rand(Constants::CO_LOCATED_ADMIN_ACTIONS.length)
      selected_opt = Constants::CO_LOCATED_ADMIN_ACTIONS.values[opt_idx]

      click_dropdown opt_idx do
        visible_options = page.find_all(".Select-option")
        expect(visible_options.length).to eq Constants::CO_LOCATED_ADMIN_ACTIONS.length
      end

      fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: generate_words(20)

      click_on "Assign Action"

      expect(page).to have_content(format(COPY::ADD_COLOCATED_TASK_CONFIRMATION_TITLE, selected_opt))
      expect(page.current_path).to eq "/queue"

      visit "/queue"
      expect(page).to have_content(format(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, 1))
      expect(page).to have_content(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1))
    end
  end
end
