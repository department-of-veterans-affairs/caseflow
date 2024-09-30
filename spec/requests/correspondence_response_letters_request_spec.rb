# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CorrespondenceResponseLetters", type: :request do
  let(:correspondence) { create(:correspondence) }
  let(:current_user) { create(:intake_user) }

  before do
    User.authenticate!(user: current_user)
  end

  describe "POST /create" do
    it "creates a Correspondence response letter" do
      # this will perform a POST request to the /correspondence_response_letters_request/create route
      post correspondence_response_letters_path, params: {
        correspondence_response_letter: {
          title: "Test Title",
          date_sent: Time.zone.now,
          letter_type: "test",
          subcategory: "test subcategory",
          reason: "test reason",
          response_window: "response window",
          user_id: current_user.id,
          correspondence_id: correspondence.id
        }
      }
      # 'response' is a special object which contain HTTP response received after a request is sent
      # response.body is the body of the HTTP response, which here contain a JSON string
      expect(JSON.parse(response.body)["title"]).to eq("Test Title")

      # # we can also check the http status of the response
      expect(response.status).to eq(200)
    end
  end
end
