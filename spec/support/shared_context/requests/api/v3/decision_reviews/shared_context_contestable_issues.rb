# frozen_string_literal: true

RSpec.configure { |rspec| rspec.shared_context_metadata_behavior = :apply_to_host_groups }

RSpec.shared_context "contestable issues request context", shared_context: :metadata do
  before { FeatureToggle.enable!(:api_v3) }
  after do
    User.instance_variable_set(:@api_user, nil)
    FeatureToggle.disable!(:api_v3)
  end
end

RSpec.shared_context "contestable issues request index context", shared_context: :metadata do
  let!(:api_key) { ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string }
  let(:veteran) { create(:veteran).unload_bgs_record }
  let(:ssn) { veteran.ssn }
  let(:response_data) { JSON.parse(response.body)["data"] }
  let(:receipt_date) { Time.zone.today }

  let(:get_issues) do
    benefit_type_url_string = benefit_type ? "/#{benefit_type}" : ""
    get(
      "/api/v3/decision_reviews/#{decision_review_type}s/contestable_issues#{benefit_type_url_string}",
      headers: {
        "Authorization" => "Token #{api_key}",
        "X-VA-SSN" => ssn,
        "X-VA-Receipt-Date" => receipt_date.try(:strftime, "%F") || receipt_date
      }
    )
  end
end
