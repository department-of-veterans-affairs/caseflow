describe JobMessageDeletionMiddleware do
  let(:sqs) { Aws::SQS::Client.new(stub_responses: true) }
  let(:msg) { OpenStruct.new(
    queue_url: 'http://localhost:4576/000000000000/caseflow_development_low_priority',
    data: OpenStruct.new(receipt_handle: '123456'),
    client: sqs)
  }
  let(:quarterly_notification_job_body) {{'job_class' => 'QuarterlyNotificationsJob'}}
  let(:caseflow_job_body) {{'job_class' => 'CaseflowJob'}}
  let(:subject) {JobMessageDeletionMiddleware.new}

  it 'deletes SQS message for QuarterlyNotificationsJob' do
    expect(sqs).to receive(:delete_message).with(queue_url: msg.queue_url, receipt_handle: msg.data.receipt_handle)
    test_yield_statement = subject.call(nil, nil, msg, quarterly_notification_job_body) {'Executes middleware block'}
    expect(test_yield_statement).to eql('Executes middleware block')
  end

  it 'does not delete SQS message for all jobs' do
    expect(sqs).not_to receive(:delete_message).with(queue_url: msg.queue_url, receipt_handle: msg.data.receipt_handle)
    test_yield_statement = subject.call(nil, nil, msg, caseflow_job_body) {'Executes middleware block'}
    expect(test_yield_statement).to eql('Executes middleware block')
  end
end
