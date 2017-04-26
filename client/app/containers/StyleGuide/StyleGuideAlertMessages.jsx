import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import AlertMessage from '../../components/AlertMessage';

export default function StyleGuideAlertMessages() {
  /* eslint-disable max-len */
  let message = "We’ve recorded your explanation and placed the claim back in the queue. You can try establishing another claim or go back to your Work History."
  /* eslint-enable max-len */

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
   <AlertMessage
       title="Establishment Cancelled"
       leadMessageList={[message]} />
  </div>;
}
