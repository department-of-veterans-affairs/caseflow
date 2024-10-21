# frozen_string_literal: true

describe SensitivityChecker do
  let!(:current_user) { create(:user) }
  subject(:described) { described_class.new(current_user) }

  let(:user) { create(:user) }
  let(:veteran) { create(:veteran) }

  let!(:bgs) { BGSService.new }
  let(:mock_sensitivity_checker) { instance_double(BGSService) }
  let(:mock_error_handler) { instance_double(ErrorHandlers::ClaimEvidenceApiErrorHandler) }

  before do
    allow(ErrorHandlers::ClaimEvidenceApiErrorHandler).to receive(:new).and_return(mock_error_handler)
    allow(BGSService).to receive(:new).and_return(mock_sensitivity_checker)

    allow(mock_sensitivity_checker).to receive(:fetch_person_info) do |vbms_id|
      bgs.fetch_person_info(vbms_id)
    end

    allow(mock_sensitivity_checker).to receive(:fetch_veteran_info) do |vbms_id|
      bgs.fetch_veteran_info(vbms_id)
    end
  end

  describe "#sensitivity_level_for_user" do
    it "returns the sensitivity level" do
      expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
        .with(user).and_return(5)

      expect(described.sensitivity_level_for_user(user)).to eq 5
    end

    context "when an exception is raised" do
      it "reports the exception and returns nil" do
        error = StandardError.new

        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
          .with(user).and_raise(error)
        expect(SecureRandom).to receive(:uuid).and_return("1234")
        expect(mock_error_handler).to receive(:handle_error)
          .with(
            error: error,
            error_details: {
              user_css_id: current_user.css_id,
              user_sensitivity_level: "Error occurred in SensitivityChecker",
              error_uuid: "1234"
            }
          )

        expect(described.sensitivity_level_for_user(user)).to eq nil
      end
    end
  end

  describe "#sensitivity_levels_compatible?" do
    context "when the sensitivity levels are compatible" do
      it "returns true" do
        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
          .with(user).and_return(Random.new.rand(4..9))
        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_veteran)
          .with(veteran).and_return(Random.new.rand(1..4))

        expect(described.sensitivity_levels_compatible?(user: user, veteran: veteran)).to eq true
      end
    end

    context "when the sensitivity levels are NOT compatible" do
      it "returns false" do
        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
          .with(user).and_return(Random.new.rand(1..4))
        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_veteran)
          .with(veteran).and_return(Random.new.rand(4..9))

        expect(described.sensitivity_levels_compatible?(user: user, veteran: veteran)).to eq false
      end
    end

    context "when the BGS call raises an exception" do
      it "reports the exception and returns false" do
        error = StandardError.new

        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
          .with(user).and_raise(error)
        expect(SecureRandom).to receive(:uuid).and_return("1234")
        expect(mock_error_handler).to receive(:handle_error)
          .with(
            error: error,
            error_details: {
              user_css_id: current_user.css_id,
              user_sensitivity_level: "Error occurred in SensitivityChecker",
              error_uuid: "1234"
            }
          )

        expect(described.sensitivity_levels_compatible?(user: user, veteran: veteran)).to eq false
      end
    end
  end
end
