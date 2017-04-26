import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default function StyleGuideStatusMessages() {
  return <div>
    <StyleGuideComponentTitle
      title="Status Messages"
      id="status_messages"
      link="StyleGuideStatusMessages.jsx"
      subsection={true}
    />
  <p>Status messages are shown when Caseflow encounters an error such as 500 or 400
    http error codes. They are also shown when a user doesn’t have access to view a
    particular page or application. These messages are more neutral with a
    <code>dark-grey</code> title, an explanation of what is going on, and next steps
    the user can take.</p>
  </div>;
}
