# frozen_string_literal: true

describe Hearings::CreateNonVirtualConferenceJob, type: :job do
  include ActiveJob::TestHelper

  # context "#subject_for_conference" do
  #   include_context "Enable both conference services"

  #   let(:assigned_date) { "Sep 21, 2023" }
  #   let(:id) { 2_000_006_656 }
  #   let(:expected_date_parsed) { Date.parse(assigned_date) }
  #   let(:hearing_day) do
  #     build(
  #       :hearing_day,
  #       scheduled_for: expected_date_parsed,
  #       id: id
  #     )
  #   end

  #   subject { hearing_day.subject_for_conference }

  #   it "returns the expected meeting conference details" do
  #     expected_date = "09 21, 2023"
  #     is_expected.to eq("#{hearing_day.id}_#{expected_date}")
  #   end

  #   context "nbf and exp" do
  #     subject { hearing_day.nbf }

  #     it "returns correct nbf" do
  #       expect subject == 1_695_254_400
  #     end

  #     before do
  #       subject { hearing_day.exp }
  #     end

  #     it "returns correct exp" do
  #       expect subject == 1_695_340_799
  #     end
  #   end
  # end
  # Remove for new functionality (From hearing day)
  # if FeatureToggle.enabled?(:webex_conference_service)
  #   links << WebexConferenceLink.find_or_create_by!(
  #     hearing_day: self,
  #     created_by: created_by
  #   )
  # end
end
