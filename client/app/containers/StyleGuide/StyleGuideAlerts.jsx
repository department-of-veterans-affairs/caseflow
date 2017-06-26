import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import Alert from '../../components/Alert';

export default function StyleGuideAlerts() {
  return <div>
      <StyleGuideComponentTitle
        title="Alerts"
        id="alerts"
        link="StyleGuideAlerts.jsx"
      />
    <p>Alerts allow us to communicate important changes and time sensitive information.
      This includes errors, warnings, and general updates.
      We also use them as a validation message that alerts someone that they just
      did something that needs to be corrected or as confirmation that a task was
      completed successfully.</p>
      <Alert
        title="Success Status"
        type="success">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.
      </Alert>
      <Alert
        title="Error Status"
        type="error">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.
      </Alert>
      <Alert
        title="Warning Status"
        type="warning">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.
      </Alert>
      <Alert
        title="Informative Status"
        type="info">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.
      </Alert>
    </div>;
}
