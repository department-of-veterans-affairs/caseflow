# frozen_string_literal: true

describe Seeds::StaticTestCaseData do
  let(:seed) { described_class.new }

  context "initial values" do
    it "are correctly set with no previous data" do
      expect(seed.instance_variable_get(:@file_number)).to eq(400_000_000)
      expect(seed.instance_variable_get(:@participant_id)).to eq(800_000_000)
    end

    it "are correctly set if seed has been previously run" do
      Veteran.create!(file_number: 400_000_001)
      new_seed = described_class.new

      expect(new_seed.instance_variable_get(:@file_number)).to eq(400_002_000)
      expect(new_seed.instance_variable_get(:@participant_id)).to eq(800_002_000)
    end
  end

  context "#seed!" do
    context "for APPEALS-8386, ASR-272 Calculation Functionality for Timely/Untimely Checkbox on DAS" do
      # required because the judge team for user BVAGSPORER is used specifically in the described_class
      # and judge team attorneys need to be in VACOLS for creating the attorney tasks
      before do
        { "BVAGSPORER" => { attorneys: %w[BVAOTRANTOW BVAGBOTSFORD BVAJWEHNER1] },
          "BVAEBECKER" => { attorneys: %w[BVAKBLOCK BVACMERTZ BVAHLUETTGEN] } }.each_pair do |judge_css_id, h|
          judge = User.find_or_create_by(css_id: judge_css_id, station_id: 101)
          create(:staff, :judge_role, sdomainid: judge_css_id)
          judge_team = JudgeTeam.for_judge(judge) || JudgeTeam.create_for_judge(judge)
          h[:attorneys].each do |css_id|
            judge_team.add_user(User.find_or_create_by(css_id: css_id, station_id: 101))
            create(:staff, :attorney_role, sdomainid: css_id)
          end
        end
      end

      it "creates appeals and veterans, and increments file_number and participant_id" do
        seed.seed!
        expect(Appeal.count).to be >= 12
        expect(Veteran.count).to be >= 12
        expect(seed.instance_variable_get(:@file_number)).to be >= 400_000_012
        expect(seed.instance_variable_get(:@participant_id)).to be >= 800_000_012
      end
    end
  end
end
