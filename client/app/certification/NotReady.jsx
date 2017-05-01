import React from 'react';
import StatusMessage from '../components/StatusMessage';

const NotReady = () => {
  const message = 'Looks like this appeal is not ready for certification.' +
  ' Please check VACOLS.';

  return <div>
    <StatusMessage
      title="Appeal is not ready for certification."
      leadMessageList={[message]} />
  </div>;
};

export default NotReady;
