import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import Alert from '../../components/Alert';

export default class StyleGuideAlerts extends React.PureComponent {
  render = () => {
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

      <StyleGuideComponentTitle
        title="Alerts Slim"
        id="alerts-slim"
        link="StyleGuideAlerts.jsx"
      />
      <p>
        Alert Slim is a lighter version of our banner alerts designed for sections
        in our app with a different layout, specifically to call out features with
        smaller dimensions. Currently it is being used in the Caseflow Reader Menu.
      </p>
      <div className="cf-sg-alert-slim">
        <Alert
          type="success">
          Success status slim
        </Alert>
      </div>
      <div className="cf-sg-alert-slim">
        <Alert
          type="warning">
          Warning status slim
        </Alert>
      </div>
      <div className="cf-sg-alert-slim">
        <Alert
          type="error">
          Error status slim
        </Alert>
      </div>
      <div className="cf-sg-alert-slim">
        <Alert
          type="info">
          Informative status slim
        </Alert>
      </div>
    </div>;
  }
}

