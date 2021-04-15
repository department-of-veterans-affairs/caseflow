
# frozen_string_literal: true

RSpec.shared_context("with Clerk of the Board user") do
  let(:cotb_org) { ClerkOfTheBoard.singleton }

  before do
    cotb_org.add_user(user)
    User.authenticate!(user: user)
  end
end

RSpec.shared_context("with feature toggle") do
  before do
    FeatureToggle.enable!(:recognized_granted_substitution_after_dd)
  end
  after { FeatureToggle.disable!(:recognized_granted_substitution_after_dd) }
end

RSpec.shared_context "with existing relationships" do
  let(:relationships) do
    [
      {
        first_name: "BOB",
        last_name: "VANCE",
        ptcpnt_id: "5382910292",
        relationship_type: "Spouse"
      },
      {
        first_name: "BILLY",
        last_name: "VANCE",
        ptcpnt_id: "12345",
        relationship_type: "Child"
      },
      {
        first_name: "BLAKE",
        last_name: "VANCE",
        ptcpnt_id: "11111",
        relationship_type: "Other"
      }
    ]
  end

  before do
    allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(relationships)
  end
end

RSpec.shared_examples("fill substitution form") do
  it "allows user to designate a subsitute appellant" do
    step "user sets basic info for substitution" do
      visit "/queue/appeals/#{appeal.uuid}"

      # Navigate to substitution page
      page.find("button", text: "+ Add Substitute").click

      expect(page).to have_content "Select substitute appellant"
      expect(page).to have_css(".cf-progress-bar-activated", text: "Select substitute appellant")

      # Fill form
      fill_in "When was substitution granted for this appellant?", with: substitution_date

      # Select second relationship
      find("label[for=participantId_#{relationships[1][:ptcpnt_id]}").click

      page.find("button", text: "Continue").click
    end

    # POA step will be relevant for future work
    # step "select POA form" do
    #   expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}/substitute_appellant/poa")

    #   expect(page).to have_content COPY::SUBSTITUTE_APPELLANT_SELECT_POA_TITLE
    #   expect(page).to have_css(".cf-progress-bar-activated", text: "Select substitute appellant")
    #   expect(page).to have_css(".cf-progress-bar-activated", text: "Select POA")

    #   page.find("button", text: "Continue").click
    # end

    step "create tasks form" do
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}/substitute_appellant/tasks")

      expect(page).to have_content COPY::SUBSTITUTE_APPELLANT_CREATE_TASKS_TITLE
      expect(page).to have_css(".cf-progress-bar-activated", text: "Select substitute appellant")
      # expect(page).to have_css(".cf-progress-bar-activated", text: "Select POA")
      expect(page).to have_css(".cf-progress-bar-activated", text: "Create task")

      page.find("button", text: "Continue").click
    end

    step "review/confirm page" do
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}/substitute_appellant/review")

      expect(page).to have_content COPY::SUBSTITUTE_APPELLANT_REVIEW_TITLE
      expect(page).to have_css(".cf-progress-bar-activated", text: "Select substitute appellant")
      # expect(page).to have_css(".cf-progress-bar-activated", text: "Select POA")
      expect(page).to have_css(".cf-progress-bar-activated", text: "Create task")
      expect(page).to have_css(".cf-progress-bar-activated", text: "Review")

      page.find("button", text: "Confirm").click
    end

    # Flesh out other steps
    # After final step, verify routing to Case Details for new appeal and success alert
  end
end

