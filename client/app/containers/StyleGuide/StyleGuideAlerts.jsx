import React from 'react';
import Button from '../../components/Button';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import AlertBanner from '../../components/AlertBanner';

export default class StyleGuideAlerts extends React.Component {
  render() {
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
      <AlertBanner
        title="Success Status"
        type="success">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.
      </AlertBanner>
      <AlertBanner
        title="Error Status"
        type="error">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.
      </AlertBanner>
      <AlertBanner
        title="Warning Status"
        type="warning">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.
      </AlertBanner>
      <AlertBanner
        title="Informative Status"
        type="info">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod.
      </AlertBanner>
    </div>
  }
}
