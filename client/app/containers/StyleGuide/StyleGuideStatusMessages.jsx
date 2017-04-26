import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import StatusMessage from '../../components/StatusMessage';

export default function StyleGuideStatusMessages() {
  /* eslint-disable max-len */
  let message = "We've recorded your explanation and placed the claim on hold. You can try establishing another claim or go view held claims in your Work History.";
  /* eslint-enable max-len */

  return <div>
    <StyleGuideComponentTitle
      title="Status Messages"
      id="status_messages"
      link="StyleGuideStatusMessages.jsx"
      isSubsection={true}
    />
  <p>Status messages are shown when Caseflow encounters an error such as 500 or 400
    http error codes. They are also shown when a user doesn’t have access to view a
    particular page or application. These messages are more neutral with a
    <code>dark-grey</code> title, an explanation of what is going on, and next steps
    the user can take.</p>
    <StatusMessage
      title="Claim Held"
      leadMessageList={[message]} />
  </div>;
}
