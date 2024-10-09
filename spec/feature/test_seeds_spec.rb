# frozen_string_literal: true

# RSpec.feature "Test Seeds" do
#   let!(:current_user) do
#     user = create(:user, css_id: "BVADWISE")
#     CDAControlGroup.singleton.add_user(user)
#     User.authenticate!(user: user)
#   end

#   context "user is a Tester admin creating seeds" do
#     before do
#       OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
#     end

#     scenario "visits the test seeds page" do
#       visit "test/seeds"
#       confirm_page_and_section_loaded
#     end
#   end
# end

# def confirm_page_and_section_loaded
#   expect(page).to have_content(COPY::TEST_SEEDS_RUN_SEEDS)
#   find_field("count-aod-seeds").set(2)
#   find(:xpath, "//*[@id='button-Run-Demo-Aod-Seeds']").click
# end

# def confirm_page_and_section_loaded
#   expect(page).to have_content(COPY::TEST_SEEDS_RUN_SEEDS)

#   aod_seed_field = find_field("count-aod-seeds", visible: :all)
#   aod_seed_field.set(2)

#   run_demo_button = find_button("Run Demo Aod Seeds")
#   run_demo_button.click
# end
