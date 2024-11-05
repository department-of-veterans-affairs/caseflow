# frozen_string_literal: true

describe NationalHearingQueueEntryRefreshJob, :postgres do
  describe '#perform' do
    context 'when it follows the happy path' do
      it 'completes the national hearing queue refresh without fail' do
        expect{ NationalHearingQueueEntryRefreshJob.perform_now }.not_to raise_error
      end
    end

    context 'when the queue refresh is expecting to timeout' do
      #allow(object).to receive(:method).and_return(value)
      before(:each) do
        allow(NationalHearingQueueEntry).to receive(:refresh).and_raise(ActiveRecord::StatementTimeout)
      end

      it 'calls set_timeout to change the timeout value and calls perform' do
        job = NationalHearingQueueEntryRefreshJob.new
        expect(job).to receive(:perform).exactly(2).times.and_call_original
        expect(job).to receive(:set_timeout).exactly(2).times

        job.perform_now
      end

      it 'logs the error' do
        job = NationalHearingQueueEntryRefreshJob.new
        expect(job).to receive(:log_error)

        job.perform_now
      end
    end

    context 'when the queue refresh is expecting a standard error' do
      before do
        allow(NationalHearingQueueEntry).to receive(:refresh).and_raise(StandardError)
      end
      it 'logs the error' do
        job = NationalHearingQueueEntryRefreshJob.new
        expect(job).to receive(:log_error)

        job.perform_now
      end
    end
  end
end
