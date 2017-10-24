import React from 'react';
import StyleGuideSuccessMessages from './StyleGuideSuccessMessages';
import StyleGuideStatusMessages from './StyleGuideStatusMessages';
import StyleGuideAlertMessages from './StyleGuideAlertMessages';

export default function StyleGuideMessages() {
  return <div><br />
    <div className="usa-width-one-whole">
      <h2 id="messages">Messages</h2>
    </div>
    <p>Messages are a frequent layout used in Caseflow. These messages are shown
    when the user has completed a task, when there is an error, and to indicate status.</p>
    <p>All messages are shown in the standard App Canvas. The messages contain a
      <code>heading 1</code>, whose colors vary based on context, and <code>lead</code>
      follow-up text. The follow up text often contains context and instructions
      on what the user can do next.</p>
    <StyleGuideSuccessMessages />
    <StyleGuideStatusMessages />
    <StyleGuideAlertMessages />
    <br />
  </div>;
}
