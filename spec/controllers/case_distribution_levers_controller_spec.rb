# frozen_string_literal: true


RSpec.describe CaseDistributionLeversController, :all_dbs, type: :controller do
  let!(:admin_user) { User.authenticate!(roles: ["Admin"]) }
  let!(:lever_user) { create(:lever_user) }
  # //let!(:group_user) { User.authenticate!(roles: ["LeverGroupUser"]) }

  let!(:lever1) {create(:case_distribution_lever,
    item: "lever_1",
    title: "lever 1",
    description: "This is the first lever. It is a boolean with the default value of true. Therefore there should be a two radio buttons that display true and false as the example with true being the default option chosen. This lever is active so it should be in the active lever section",
    data_type: "boolean",
    value: true,
    unit: "",
  )}
  let!(:lever2) {create(:case_distribution_lever,
    item: "lever_2",
    title: "Lever 2",
    description: "This is the second lever. It is a number data type with the default value of 42. Therefore there should be a number input that displays 42 and 'days' as the unit. This lever is active so it should be in the active lever section",
    data_type: "number",
    value: 55,
    unit: "Days",
  )}

  let!(:audit_lever_entity1) {create(:case_distribution_audit_lever_entry,
    user: admin_user,
    user_name: "john smith",
    created_at: "2023-07-01 10:10:01",
    title: 'Lever 1',
    previous_value: 10,
    update_value: 42,
    case_distribution_lever: lever2
  )}
  let!(:audit_lever_entity2) {create(:case_distribution_audit_lever_entry,
    user: admin_user,
    user_name: "john smith",
    created_at: "2023-07-01 10:11:01",
    title: 'Lever 1',
    previous_value: 42,
    update_value: 55,
    case_distribution_lever: lever2
  )}

  let!(:levers) {[lever1, lever2]}
  let!(:lever_history) {[audit_lever_entity1, audit_lever_entity2]}

  before do
  end

  describe "GET acd_lever_index", :type => :request do
    it "redirects the user to the unauthorized page if they are not authorized" do

      User.authenticate!(user: create(:user))
      get "/acd-controls"

      expect(response.status).to eq 302
      expect(response.body).to match(/unauthorized/)
    end

    it "renders a page with the correct levers when user is allowed to view the page" do
      User.authenticate!(user: lever_user)
      get "/acd-controls"

      expect(response.status).to eq 200
      expect(response.body).to eq(2)
    end

    it "renders a page with the correct levers when user is an admin" do
      User.authenticate!(roles: ["Admin"])
      get "/acd-controls"

      expect(response.status).to eq 200
      expect(user.roles).to eq(2)
    end
  end

  describe "POST update_levers" do
    it "updates all provided levers" do
      expect(lever1).to eq(2)
    end

    it "returns an error message then the format of a lever in invalid" do
      expect(levers).to eq(2)
    end
  end

  describe "GET show_audit_lever_entries" do
    it "returns all the audit lever entries from only the past year" do
      expect(1).to eq(2)
    end
  end

  describe "POST add_audit_lever_entries" do
    it "creates records for the provided audit lever entries in the database" do
      expect(1).to eq(2)
    end

    it "returns an error message when the format of the audit lever entry is invalid" do
      expect(1).to eq(2)
    end
  end


end
