# frozen_string_literal: true

RSpec.describe CaseDistributionLeversController, :all_dbs, type: :controller do
  before { Seeds::CaseDistributionLevers.new.seed! }
  let!(:lever_user) { create(:user) }
  let!(:lever_user2) { create(:user) }

  # rubocop:disable Layout/LineLength
  let!(:lever1) do
    create(
      :case_distribution_lever,
      item: "lever_1",
      title: "lever 1",
      description: "This is the first lever. It is a boolean with the default value of true. Therefore there should be a two radio buttons that display true and false as the example with true being the default option chosen. This lever is active so it should be in the active lever section",
      data_type: Constants.ACD_LEVERS.data_types.boolean,
      value: true,
      unit: "",
      lever_group: "static",
      lever_group_order: 1
    )
  end
  let!(:lever2) do
    create(
      :case_distribution_lever,
      item: "request_more_cases_minimum",
      title: "request_more_cases_minimum",
      description: "This is the second lever. It is a number data type with the default value of 42. Therefore there should be a number input that displays 42 and 'days' as the unit. This lever is active so it should be in the active lever section",
      data_type: Constants.ACD_LEVERS.data_types.number,
      value: 55,
      unit: "Days",
      lever_group: "static",
      lever_group_order: 2
    )
  end
  let!(:audit_lever_entry1) do
    create(
      :case_distribution_audit_lever_entry,
      user: lever_user,
      created_at: 11.months.ago.at_noon,
      previous_value: 10,
      update_value: 42,
      case_distribution_lever: lever2
    )
  end
  let!(:audit_lever_entry1_serialized) do
    CaseDistributionAuditLeverEntrySerializer.new(audit_lever_entry1).serializable_hash[:data][:attributes]
  end
  let!(:audit_lever_entry2) do
    create(
      :case_distribution_audit_lever_entry,
      user: lever_user,
      created_at: 10.months.ago.at_noon,
      previous_value: 42,
      update_value: 55,
      case_distribution_lever: lever2
    )
  end
  let!(:audit_lever_entry2_serialized) do
    CaseDistributionAuditLeverEntrySerializer.new(audit_lever_entry2).serializable_hash[:data][:attributes]
  end
  let!(:old_audit_lever_entry) do
    create(
      :case_distribution_audit_lever_entry,
      user: lever_user,
      created_at: 13.months.ago.at_noon,
      previous_value: 42,
      update_value: 55,
      case_distribution_lever: lever2
    )
  end
  let!(:old_audit_lever_entry_serialized) do
    CaseDistributionAuditLeverEntrySerializer.new(old_audit_lever_entry).serializable_hash[:data][:attributes]
  end

  let!(:levers) { Seeds::CaseDistributionLevers.levers + [lever1, lever2] }

  # rubocop:enable Layout/LineLength

  before do
    CDAControlGroup.singleton.add_user(lever_user)
  end

  describe "GET acd-controls", type: :request do
    it "redirects the user to the unauthorized page if they are not authorized" do
      User.authenticate!(user: create(:user))
      get "/acd-controls"

      expect(response.status).to eq 302
      expect(response.body).to match(/unauthorized/)
    end

    it "renders correctly for non-admin user" do
      User.authenticate!(user: lever_user)
      get "/acd-controls"

      request_levers = @controller.view_assigns["acd_levers"]
      request_history = @controller.view_assigns["acd_history"]
      request_user_is_an_admin = @controller.view_assigns["user_is_an_acd_admin"]

      expect(response.status).to eq 200
      expect(request_levers.count).to eq(levers.count)
      expect(request_levers).to include(lever1)
      expect(request_levers).to include(lever2)
      expect(request_history).to match_array([audit_lever_entry1_serialized, audit_lever_entry2_serialized])
      expect(request_user_is_an_admin).to be_falsey
    end

    it "renders correctly for an admin" do
      User.authenticate!(user: lever_user)
      OrganizationsUser.make_user_admin(lever_user, CDAControlGroup.singleton)
      get "/acd-controls"

      request_levers = @controller.view_assigns["acd_levers"]
      request_history = @controller.view_assigns["acd_history"]
      request_user_is_an_admin = @controller.view_assigns["user_is_an_acd_admin"]

      expect(response.status).to eq 200
      expect(request_levers.count).to eq(levers.count)
      expect(request_levers).to include(lever1)
      expect(request_levers).to include(lever2)
      expect(request_history).to match_array([audit_lever_entry1_serialized, audit_lever_entry2_serialized])
      expect(request_user_is_an_admin).to be_truthy
    end
  end

  describe "GET levers" do
    it "redirects the user to the unauthorized page if they are not authorized" do
      User.authenticate!(user: create(:user))
      get "levers"

      expect(response.status).to eq 302
      expect(response.body).to match(/unauthorized/)
    end

    it "renders a page with the grouped levers and lever history" do
      lever_keys = %w[static batch affinity docket_distribution_prior docket_time_goal docket_levers internal]
      User.authenticate!(user: lever_user)
      OrganizationsUser.make_user_admin(lever_user, CDAControlGroup.singleton)
      get "levers"

      expect(response.status).to eq 200
      result = JSON.parse(response.body)
      expect(result).to be_a(Hash)
      expect(result.keys).to match_array(%w[levers lever_history])
      expect(result["levers"]).to be_a(Hash)
      expect(result["levers"].keys).to match_array(lever_keys)
      expect(result["lever_history"]).to be_a(Array)
    end
  end

  describe "GET case-distribution-controls", type: :request do
    it "redirects the user to the unauthorized page if they are not authorized" do
      User.authenticate!(user: create(:user))
      get "/case-distribution-controls"

      expect(response.status).to eq 302
      expect(response.body).to match(/unauthorized/)
    end

    it "renders correctly for non-admin user" do
      User.authenticate!(user: lever_user)
      get "/case-distribution-controls"

      request_levers = @controller.view_assigns["acd_levers"]
      request_history = @controller.view_assigns["acd_history"]
      request_user_is_an_admin = @controller.view_assigns["user_is_an_acd_admin"]

      expect(response.status).to eq 200
      expect(request_levers.count).to eq(levers.count)
      expect(request_levers).to include(lever1)
      expect(request_levers).to include(lever2)
      expect(request_history).to match_array([audit_lever_entry1_serialized, audit_lever_entry2_serialized])
      expect(request_user_is_an_admin).to be_falsey
    end

    it "renders correctly for admin user" do
      User.authenticate!(user: lever_user)
      OrganizationsUser.make_user_admin(lever_user, CDAControlGroup.singleton)
      get "/case-distribution-controls"

      request_levers = @controller.view_assigns["acd_levers"]
      request_history = @controller.view_assigns["acd_history"]
      request_user_is_an_admin = @controller.view_assigns["user_is_an_acd_admin"]

      expect(response.status).to eq 200
      expect(request_levers.count).to eq(levers.count)
      expect(request_levers).to include(lever1)
      expect(request_levers).to include(lever2)
      expect(request_history).to match_array([audit_lever_entry1_serialized, audit_lever_entry2_serialized])
      expect(request_user_is_an_admin).to be_truthy
    end
  end

  describe "POST update_levers" do
    it "redirects the user to the unauthorized page if they are not authorized" do
      User.authenticate!(user: create(:user))
      post "update_levers"

      expect(response.status).to eq 302
      expect(response.body).to match(/unauthorized/)
    end

    it "updates all provided levers" do
      User.authenticate!(user: lever_user)
      OrganizationsUser.make_user_admin(lever_user, CDAControlGroup.singleton)

      updated_lever_1 = {
        id: lever1.id,
        value: false
      }

      save_params = {
        current_levers: [updated_lever_1, lever2]
      }

      post "update_levers", params: save_params, as: :json

      expect(CaseDistributionLever.find(lever1.id).value).to eq("f")

      expect(JSON.parse(response.body)["errors"]).to be_empty
    end

    it "returns an error message then the format of a lever in invalid" do
      User.authenticate!(user: lever_user)
      OrganizationsUser.make_user_admin(lever_user, CDAControlGroup.singleton)

      invalid_updated_lever_2 = {
        id: lever2.id,
        value: false
      }

      save_params = {
        current_levers: [lever1, invalid_updated_lever_2]
      }

      post "update_levers", params: save_params, as: :json

      not_updated_lever_2 = CaseDistributionLever.find(lever2.id)

      expect(CaseDistributionLever.find(lever1.id).value).to eq("t")

      expect(not_updated_lever_2.value).to_not eq("f")
      expect(not_updated_lever_2.value).to eq("55")

      expect(JSON.parse(response.body)["errors"]).not_to be_empty
    end

    it "returns an error when the user is not an admin" do
      User.authenticate!(user: lever_user)

      invalid_updated_lever_2 = {
        id: lever2.id,
        value: false
      }

      save_params = {
        current_levers: [lever1, invalid_updated_lever_2]
      }

      post "update_levers", params: save_params, as: :json

      expect(response.status).to eq 200
      expect(JSON.parse(response.body)["message"]).to eq(["UNAUTHORIZED"])
      expect(JSON.parse(response.body)["user_is_an_acd_admin"]).to be_falsey
    end

    it "does not update any lever when the user is not an admin" do
      User.authenticate!(user: lever_user)

      invalid_updated_lever_2 = {
        id: lever2.id,
        value: false
      }

      save_params = {
        current_levers: [lever1, invalid_updated_lever_2]
      }

      post "update_levers", params: save_params, as: :json

      not_updated_lever_2 = CaseDistributionLever.find(lever2.id)

      expect(CaseDistributionLever.find(lever1.id).value).to eq("t")

      expect(not_updated_lever_2.value).to_not eq("f")
      expect(not_updated_lever_2.value).to eq("55")
    end
  end
end
