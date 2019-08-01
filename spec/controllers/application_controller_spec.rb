# frozen_string_literal: true

require "rails_helper"

describe ApplicationController, type: :controller do
  let(:user) { build(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "#feedback" do
    it "allows all users to see feedback page" do
      get :feedback

      expect(response.status).to eq 200
    end
  end
end
