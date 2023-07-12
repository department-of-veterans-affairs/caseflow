# frozen_string_literal: true

require "./app/models/batch_processes/batch_process.rb"

describe BatchProcess, :postgres do

  let!(:batch) { BatchProcess.create!(batch_id: "4c8612cf-5ff2-4e13-92cf-16fca5ed1bc7", batch_type: BatchProcessPriorityEpSync.name) }
  subject { batch }

  describe "no-op methods, need to be overridden, currently do nothing"
    context "#find_records" do
      it 'empty method - no actual test is run on this method currently' do
      end
    end

    context "#create_batch!(record)" do
      it 'empty method - no actual test is run on this method currently' do

      end
    end

    context "#process_batch!" do
      it 'empty method - no actual test is run on this method currently' do

      end
    end


  describe "#error_out_record!(record, error)" do
    let(:batch) {BatchProcess.new}
    let!(:record) { create(:priority_end_product_sync_queue)}
    let(:error) {"Rspec Test Error"}
    subject{ record }

    context "when a record encounters an error the records" do
      it "the new error message is added to error_messages" do
        batch.send(:error_out_record!, subject, error)
        subject.reload
        expect(subject.error_messages.count).to eq(1)
      end

      it "the record is inspected to see if it's STUCK" do
        batch.send(:error_out_record!, subject, error+" 1")
        batch.send(:error_out_record!, subject, error+" 2")
        batch.send(:error_out_record!, subject, error+" 3")
        subject.reload
        expect(subject.status).to eq(Constants.PRIORITY_EP_SYNC.stuck)
      end

      it "status is changed to: ERROR" do
        batch.send(:error_out_record!, subject, error)
        subject.reload
        expect(subject.status).to eq(Constants.PRIORITY_EP_SYNC.error)
      end




    end
  end


end
