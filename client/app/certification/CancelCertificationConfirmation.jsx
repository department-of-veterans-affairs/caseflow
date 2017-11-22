import React from 'react';
import StatusMessage from '../components/StatusMessage';

const CancelCertificationConfirmation = () => {
  const summaryMessage = <span>The certification has been cancelled and changes you made
    after opening it in Caseflow were not saved. Your feedback has been recorded, and will
    help the Caseflow team prioritize future improvements.</span>;

  return <div>
    <StatusMessage
      title="Certification cancelled"
      leadMessageList={[summaryMessage]}
      messageText="You can now close this window and open another appeal in VACOLS."
      type="alert" />
  </div>;
};

export default CancelCertificationConfirmation;
