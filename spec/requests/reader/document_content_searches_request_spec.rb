# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reader::DocumentContentSearchesController", type: :request do
  let!(:user) { User.authenticate!(roles: ["Reader"]) }
  let(:appeal) { create(:appeal) }

  it "is successful" do
    post "/reader/appeal/#{appeal.id}/document_content_searches"

    expect(response).to have_http_status(:success)
  end
end
