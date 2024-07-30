# frozen_string_literal: true

describe HelpController, type: :controller do
  let(:user) { build(:user) }
  let(:membership_requests) { create_list(:membership_request, 7) }
  let(:organizations) { create_list(:organization, 3) }

  before do
    membership_requests.each do |request|
      request.requestor = user
      request.save
    end
    organizations.each do |org|
      org.add_user(user)
      org.save
    end
    user.reload
    allow_any_instance_of(HelpController).to receive(:current_user).and_return(user)
  end

  context "Index Helper methods" do
    context "user_organizations" do
      it "should contain all of the current_user's organizations" do
        expect(controller.send(:user_organizations).length).to eq(3)
      end
    end

    context "pending_membership_requests" do
      it "should contain all of the current_user's assigned membership requests" do
        expect(controller.send(:pending_membership_requests).length).to eq(7)
      end
    end

    context "user_logged_in?" do
      it "should return true if the user is authenticated" do
        expect(controller.send(:user_logged_in?)).to eq(true)
      end

      it "should return false if the user is not authenticated" do
        # Set the station_id to nil since that's how the user is authenticated
        user.station_id = nil
        expect(controller.send(:user_logged_in?)).to eq(false)
      end
    end
  end
end
