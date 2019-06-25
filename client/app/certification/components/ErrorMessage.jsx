import React from 'react';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';

const ErrorMessage = () => {

  return <div>
    <StatusMessage
      title="Something went wrong"
      type="alert">
      If you continue to see this page, please contact the Caseflow team
      via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket
      via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.
    </StatusMessage>
  </div>;
};

export default ErrorMessage;
