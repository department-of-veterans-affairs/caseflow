import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default function StyleGuideAlertMessages() {
  let message1 = "We've recorded the explanation and placed the claim on hold."

  let message2 = "You can try establishing another claim or go view held claims in your Work History."

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
  </div>;
}
