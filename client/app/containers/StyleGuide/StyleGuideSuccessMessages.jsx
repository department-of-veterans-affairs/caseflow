import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import StatusMessage from '../../components/StatusMessage';

export default function StyleGuideSuccessMessages() {
  let successChecklist = ['Reviewed Remand Decision',
    'Established EP: 170RMDAMC - AMC - Remand for Station 397 - ARC',
    'VACOLS Updated: Changed Location to 98'];

  let successMessage = <span>Joe Snuffy's (ID #222222222) claim has been processed.
    <br /> You can now establish the next claim or return to your Work History.</span>;

  let wayToGo = <span>Way to go!</span>;

  let messageList = [successMessage, wayToGo];

  return <div>
    <StyleGuideComponentTitle
      title="Success Messages"
      id="success-messages"
      link="StyleGuideSuccessMessages.jsx"
      isSubsection
    />
    <p>Success messages are shown when the user has successfully completed the intended
    task of the application. The title is green, and these messages contain a checklist
    confirming the tasks the user has completed and displays actions performed by
    Caseflow in the background, such as automatically sending a letter or changing
    the location of a claim.</p>
    <StatusMessage
      checklist={successChecklist}
      title="Success!"
      leadMessageList={messageList}
      type="success" />
  </div>;
}
