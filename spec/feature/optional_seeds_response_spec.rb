# frozen_string_literal: true

require "rails_helper"
require "timecop"

RSpec.feature "acd-controls/test Page Run Generic Full Suite Appeals Seeds Button" do
  let!(:current_user) do
    user = create(:user, css_id: "BVALNICK")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let(:success_response) do
    HTTPI::Response.new(200, {}, { seeds_added: 4094 }.to_json)
  end

  before do
    allow(HTTPI).to receive(:post).with("/test/optional_seed").and_return(success_response)
  end

  scenario "user visits the acd-controls/test page and clicks the button" do
    visit "/acd-controls/test"

    click_button "Run Generic Full Suite Appeals Seeds"

    expect(HTTPI).to have_received(:post)
  end
end
