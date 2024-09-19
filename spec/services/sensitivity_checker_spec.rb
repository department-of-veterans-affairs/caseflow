# frozen_string_literal: true

describe SensitivityChecker do
  let!(:current_user) { create(:user) }
  subject(:described) { described_class.new(current_user) }

  let(:user) { create(:user) }
  let(:veteran) { create(:veteran) }

  let!(:bgs) { BGSService.new }
  let(:mock_sensitivity_checker) { instance_double(BGSService) }

  before do
    allow(BGSService).to receive(:new).and_return(mock_sensitivity_checker)

    allow(mock_sensitivity_checker).to receive(:fetch_person_info) do |vbms_id|
      bgs.fetch_person_info(vbms_id)
    end

    allow(mock_sensitivity_checker).to receive(:fetch_veteran_info) do |vbms_id|
      bgs.fetch_veteran_info(vbms_id)
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
      it "returns false" do
        error = StandardError.new

        expect(mock_sensitivity_checker).to receive(:sensitivity_level_for_user)
          .with(user).and_raise(error)
        expect(SecureRandom).to receive(:uuid).and_return("1234")
        expect(Raven).to receive(:capture_exception).with(error, extra: { error_uuid: "1234" })

        expect(described.sensitivity_levels_compatible?(user: user, veteran: veteran)).to eq false
      end
    end
  end
end
