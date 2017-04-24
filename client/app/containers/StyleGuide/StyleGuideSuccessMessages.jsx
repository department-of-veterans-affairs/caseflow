import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import SuccessMessage from '../../components/SuccessMessage'

export default function StyleGuideSuccessMessages() {
  let successChecklist = () => {
    return ["Reviewed Remand Decision",
    "Established EP: 170RMDAMC - AMC - Remand for Station 397 - ARC",
    "VACOLS Updated: Changed Location to 98"]
  }

  let messageList = () => {
    return [successMessage(), wayToGo()]
  }

  let successMessage = () => {
    return <span>Joe Snuffy's (ID #222222222) claim has been processed.
    <br /> You can now establish the next claim or return to your Work History.</span>
  }

  let wayToGo = () => {
    return <span>Way to go!</span>
  }

  return <div>
    <StyleGuideComponentTitle
      title="Success Messages"
      id="success_messages"
      link="StyleGuideSuccessMessages.jsx"
      subsection={true}
    />
  <p>Success messages are shown when the user has successfully completed the intended
    task of the application. The title is green, and these messages contain a checklist
    confirming the tasks the user has completed and displays actions performed by
    Caseflow in the background, such as automatically sending a letter or changing
    the location of a claim.</p>
  <SuccessMessage
    checklist={successChecklist()}
    title="Success!"
    messageList={messageList()} />
  </div>
}
