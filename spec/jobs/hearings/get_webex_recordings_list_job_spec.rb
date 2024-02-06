# frozen_string_literal: true

describe Hearings::GetWebexRecordingsListJob, type: :job do
  include ActiveJob::TestHelper

  let(:current_user) { create(:user, roles: ["System Admin"]) }

  subject { Hearings::GetWebexRecordingsListJob.perform_now }

  it "Returns the correct array of ids" do
    expect(subject).to eq(%w[4f914b1dfe3c4d11a61730f18c0f5387 3324fb76946249cfa07fc30b3ccbf580 42b80117a2a74dcf9863bf06264f8075])
  end
end
