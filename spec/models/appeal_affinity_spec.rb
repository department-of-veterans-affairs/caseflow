# frozen_string_literal: true

describe AppealAffinity do
  let!(:appeal_affinity) { create(:appeal_affinity, appeal: appeal) }

  context "#case" do
    subject { appeal_affinity.case }
    context "for an AMA appeal" do
      let(:appeal) { create(:appeal) }

      it "returns the Appeal object" do
        expect(subject.is_a?(Appeal)).to be true
      end
    end

    context "for a legacy appeal" do
      let(:appeal) { create(:case) }

      it "returns the VACOLS::Case object" do
        expect(subject.is_a?(VACOLS::Case)).to be true
      end
    end
  end

  # It would make more sense to place these tests into their respective model spec files, but the appeal spec file is
  # already thousands of lines long, so the functionality can be tested here since it is reliant on this model anyway
  context "ActiveRecord associations return the AffinityAppeal object" do
    subject { appeal.appeal_affinity.is_a?(AppealAffinity) }
    context "for an AMA appeal" do
      let(:appeal) { create(:appeal) }
      it { should be true }
    end

    context "for an legacy appeal" do
      let(:appeal) { create(:case) }
      it { should be true }
    end
  end

  context "factory" do
    before { Timecop.freeze }
    after { Timecop.return }

    context "when passed a priority AMA appeal" do
      let(:appeal) { create(:appeal, :advanced_on_docket_due_to_age) }

      it "correctly sets parameters" do
        expect(appeal_affinity.case_id).to eq(appeal.uuid)
        expect(appeal_affinity.case_type).to eq(appeal.class.name)
        expect(appeal_affinity.docket).to eq(appeal.docket_type)
        expect(appeal_affinity.priority).to eq(true)
        expect(appeal_affinity.affinity_start_date.to_date).to eq(Time.zone.today)
      end
    end

    context "when passed a priority VACOLS::Case" do
      let(:appeal) { create(:case, :type_cavc_remand) }

      it "correctly sets parameters" do
        expect(appeal_affinity.case_id).to eq(appeal.bfkey)
        expect(appeal_affinity.case_type).to eq(appeal.class.name)
        expect(appeal_affinity.docket).to eq("legacy")
        expect(appeal_affinity.priority).to eq(true)
        expect(appeal_affinity.affinity_start_date.to_date).to eq(Time.zone.today)
      end
    end

    context "when passed a distribution" do
      let(:appeal_affinity) { create(:appeal_affinity, distribution: distribution) }
      let(:distribution) { create(:distribution, judge: create(:user, :with_vacols_judge_record)) }

      it "correctly sets the distribution" do
        expect(appeal_affinity.distribution_id).to eq(distribution.id)
      end
    end

    context "when passed an appeal with a distributed case record" do
      # Override this from the top-level so that the DistributedCase is created first to test the factory correctly
      let(:appeal_affinity) { nil }
      let(:appeal) { create(:appeal) }
      let(:distribution) { create(:distribution, judge: create(:user, :with_vacols_judge_record)) }

      before do
        DistributedCase.create!(distribution: distribution, task: create(:distribution_task, appeal: appeal),
                                priority: false, sct_appeal: false, case_id: appeal.uuid, docket: appeal.docket_type,
                                ready_at: Time.zone.now)
      end

      it "correctly sets the appeal affinity distribution" do
        appeal_affinity = create(:appeal_affinity, appeal: appeal)
        expect(appeal_affinity.distribution_id).to eq(distribution.id)
      end
    end
  end
end
