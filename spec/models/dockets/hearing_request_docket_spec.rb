describe HearingRequestDocket do
  before do
    FeatureToggle.enable!(:ama_auto_case_distribution)
    Distribution.skip_callback(:commit, :after, :enqueue_distribution_job)
  end
  after do
    FeatureToggle.disable!(:ama_auto_case_distribution)
    Distribution.set_callback(:commit, :after, :enqueue_distribution_job)
  end

  let(:judge_user) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
  let(:distribution) { Distribution.create!(judge: judge_user) }

  describe "#age_of_n_oldest_priority_appeals" do
    subject { HearingRequestDocket.new.age_of_n_oldest_priority_appeals(10) }

    it "should return a stubbed value" do
      expect(subject).to eq([])
    end
  end

  describe "#age_of_n_oldest_priority_appeals" do
    subject { HearingRequestDocket.new.distribute_appeals(distribution) }

    it "should return a stubbed value" do
      expect(subject).to eq([])
    end
  end
end
