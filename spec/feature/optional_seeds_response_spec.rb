# frozen_string_literal: true

require "rails_helper"

RSpec.feature "acd-controls/test Page Run Generic Full Suite Appeals Seeds Button" do
  let!(:current_user) do
    user = create(:user, css_id: "BVALNICK")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:success_response) do
    HTTPI::Response.new(200, {}, { appealCount: 4094 }.to_json)
  end

  before do
    allow(HTTPI).to receive(:post).with("/test/optional_seed").and_return(success_response)
  end

  scenario "user visits the acd-controls/test page and clicks the button" do
    visit "/acd-controls/test"

    click_button "Run Generic Full Suite Appeals Seeds"
    expected_message = COPY::TEST_RESEED_GENERIC_FULL_SUITE_APPEALS_ALERTMSG.gsub("{count}", "4094")
    expect(page).to have_css '.usa-alert-text'
    expect(find(".usa-alert-text")).to have_content(expected_message)
    # expect(page).to have_content(expected_message, wait: 20)
  end
end
