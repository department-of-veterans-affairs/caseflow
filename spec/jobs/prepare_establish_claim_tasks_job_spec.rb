require "rails_helper"

describe PrepareEstablishClaimTasksJob do
  let!(:appeal_with_decision_document) do
    Generators::Appeal.create(
      vacols_record: { template: :remand_decided, decision_date: 7.days.ago },
      documents: [Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)]
    )
  end

  let!(:appeal_without_decision_document) do
    Generators::Appeal.create(
      vacols_record: :remand_decided,
      documents: [Generators::Document.build(type: "BVA Decision", received_at: 31.days.ago)]
    )
  end

  let!(:not_preparable_task) do
    EstablishClaim.create(appeal: appeal_without_decision_document)
  end

  context ".perform", focus: true do
    subject { PrepareEstablishClaimTasksJob.perform_now }

    let(:filename) { appeal_with_decision_document.decisions.first.file_name }

    before do
      allow_any_instance_of(PrepareEstablishClaimTasksJob).to receive(:expected_minimum).and_return(1)
    end

    context "when minimum number of tasks are prepared" do
      let!(:preparable_task) do
        EstablishClaim.create(appeal: appeal_with_decision_document)
      end

      before do
        expect(Appeal.repository).to receive(:fetch_document_file) { "the decision file" }
      end

      it "prepares the correct tasks" do
        subject

        expect(preparable_task.reload).to be_unassigned
        expect(not_preparable_task.reload).to be_unprepared

        # Validate that the decision content is cached in S3
        expect(S3Service.files[filename]).to eq("the decision file")
      end
    end

    context "when minimun number of tasks are not prepared" do
      context "it is the night before a weekend" do
        before { Timecop.freeze(Time.utc(2017, 5, 12, 22)) }

        it "it completes silently" do
          expect { subject }.to_not raise_error
        end
      end

      context "it is the night before a weekday" do
        before { Timecop.freeze(Time.utc(2017, 5, 11, 22)) }

        it "raises NotEnoughTasksPrepared" do
          expect { subject }.to raise_error(Caseflow::Error::NotEnoughTasksPrepared)
        end
      end
    end
  end
end
