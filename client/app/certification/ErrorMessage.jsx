import React from 'react';
import StatusMessage from '../components/StatusMessage';

const ErrorMessage = () => {

  return <div>
    <StatusMessage
      title="Something went wrong"
      leadMessageList={['If you continue to see this page, please contact the help desk.']}
      type="alert"/>
  </div>;
};

export default ErrorMessage;
