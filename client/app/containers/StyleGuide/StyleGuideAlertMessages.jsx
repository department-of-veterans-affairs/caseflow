import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import StatusMessage from '../../components/StatusMessage';

export default function StyleGuideAlertMessages() {
  let message = 'We’ve recorded your explanation and placed the claim back in the queue.' +
  ' You can try establishing another claim or go back to your Work History.';

  return <div>
    <StyleGuideComponentTitle
      title="Alert Messages"
      id="alert_messages"
      link="StyleGuideAlertMessages.jsx"
      isSubsection={true}
    />
    <p>Alert messages are often shown when the user has destroyed data by canceling
    their work. These messages have red titles to reinforce that the user did not
    complete the intended task of the application, a brief explanation of what happened,
     and next steps.</p>
    <StatusMessage
      title="Establishment Cancelled"
      leadMessageList={[message]}
      type="alert" />
  </div>;
}
