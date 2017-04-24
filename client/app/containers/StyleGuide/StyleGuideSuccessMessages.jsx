import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default function StyleGuideSuccessMessages() {
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
  </div>
}
