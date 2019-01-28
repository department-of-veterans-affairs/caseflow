describe Distribution do
  let(:judge) { FactoryBot.create(:user) }
  let!(:judge_team) { JudgeTeam.create_for_judge(judge) }
  let(:member_count) { 5 }
  let(:attorneys) { FactoryBot.create_list(:user, member_count) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }

  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
    attorneys.each do |u|
      OrganizationsUser.add_user_to_organization(u, judge_team)
    end

    # set up a couple of extra judge teams
    2.times do
      team = JudgeTeam.create_for_judge(FactoryBot.create(:user))
      FactoryBot.create_list(:user, 5).each do |attorney|
        OrganizationsUser.add_user_to_organization(attorney, team)
      end
    end
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  # We use StartDistributionJob.perform_now in the test environment.
  #
  # context "StartDistributionJob" do
  #   ActiveJob::Base.queue_adapter = :test

  #   it "enqueues a job" do
  #     expect { Distribution.create(judge: judge) }.to have_enqueued_job(StartDistributionJob)
  #   end
  # end

  context "#distribute!" do
    subject { Distribution.create(judge: judge) }

    let!(:priority_cases) do
      (1..15).map do |i|
        create(:case,
               :aod,
               bfd19: 1.year.ago,
               bfac: "1",
               bfmpro: "ACT",
               bfcurloc: "81",
               bfdloout: i.days.ago,
               folder: build(:folder, tinum: "1801#{format('%03d', i)}", titrnum: "123456789S"))
      end
    end

    let!(:nonpriority_cases) do
      (16..100).map do |i|
        create(:case,
               bfd19: 1.year.ago,
               bfac: "1",
               bfmpro: "ACT",
               bfcurloc: "81",
               bfdloout: i.days.ago,
               folder: build(:folder, tinum: "1801#{format('%03d', i)}", titrnum: "123456789S"))
      end
    end

    let!(:same_judge_priority_hearings) do
      priority_cases[0..1].map do |appeal|
        create(:case_hearing,
               :disposition_held,
               folder_nr: appeal.bfkey,
               hearing_date: 1.month.ago,
               board_member: judge.vacols_attorney_id)
      end
    end

    let!(:same_judge_nonpriority_hearings) do
      nonpriority_cases[29..33].map do |appeal|
        create(:case_hearing,
               :disposition_held,
               folder_nr: appeal.bfkey,
               hearing_date: 1.month.ago,
               board_member: judge.vacols_attorney_id)
      end
    end

    let!(:other_judge_hearings) do
      nonpriority_cases[2..27].map do |appeal|
        create(:case_hearing,
               :disposition_held,
               folder_nr: appeal.bfkey,
               hearing_date: 1.month.ago,
               board_member: "1234")
      end
    end

    it "correctly distributes cases to the judge" do
      subject.distribute!
      expect(subject.valid?).to eq(true)
      expect(subject.status).to eq("completed")
      expect(subject.completed_at).to eq(Time.zone.now)
      expect(subject.statistics["batch_size"]).to eq(15)
      expect(subject.statistics["total_batch_size"]).to eq(45)
      expect(subject.statistics["priority_count"]).to eq(15)
      expect(subject.distributed_cases.count).to eq(15)
      expect(subject.distributed_cases.first.docket).to eq("legacy")
      expect(subject.distributed_cases.first.ready_at).to eq(2.days.ago.beginning_of_day)
      expect(subject.distributed_cases.where(priority: true).count).to eq(5)
      expect(subject.distributed_cases.where(genpop: true).count).to eq(8)
      expect(subject.distributed_cases.where(priority: true, genpop: false).count).to eq(2)
      expect(subject.distributed_cases.where(priority: false, genpop_query: "not_genpop").count).to eq(1)
      expect(subject.distributed_cases.where(priority: false, genpop_query: "any").map(&:docket_index).max).to eq(35)
    end

    # context "when the judge is only recieves hearing cases" do
    #   it "correctly distributes cases to the judge" do
    #     subject.distribute!
    #     expect(subject.valid?).to eq(true)
    #     expect(subject.statistics["batch_size"]).to eq(10)
    #     expect(subject.distributed_cases.count).to eq(7)
    #     expect(subject.distributed_cases.where(genpop: false).count).to eq(7)
    #   end
    # end

    context "when the job errors" do
      it "marks the distribution as error" do
        allow_any_instance_of(LegacyDocket).to receive(:distribute_priority_appeals).and_raise(StandardError)
        expect { subject.distribute! }.to raise_error(StandardError)
        expect(subject.status).to eq("error")
      end
    end
  end

  context "validations" do
    subject { Distribution.create(judge: user) }

    let(:user) { judge }

    context "when the user is not a judge in VACOOLS" do
      let(:user) { create(:user) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :not_judge)
      end
    end

    context "when the judge has an unassigned legacy appeal" do
      let!(:legacy_appeal) { create(:case, bfcurloc: vacols_judge.slogid) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :unassigned_cases)
      end
    end

    context "when the judge has an unassigned AMA appeal" do
      let!(:task) { create(:ama_judge_task, assigned_to: judge) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
        expect(subject.errors.details[:judge]).to include(error: :unassigned_cases)
      end
    end
  end
end
