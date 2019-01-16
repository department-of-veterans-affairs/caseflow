import React from 'react';
import Alert from '../../components/Alert';

export class ErrorAlert extends React.PureComponent {
  render() {
    const errorObject = {
      decisionIssueUpdateFailed: {
        title: 'Something went wrong',
        body: 'The dispositions for this task could not be saved.' +
              ' Please try submitting again. If the problem persists, please contact Caseflow support.'
      }
    }[this.props.errorCode];

    return <Alert title={errorObject.title} type="error" lowerMargin>
      {errorObject.body}
    </Alert>;
  }
}

export class SuccessAlert extends React.PureComponent {
  render() {
    const successObject = {
      decisionIssueUpdateSucceeded: {
        title: 'Decision Completed',
        body: `You successfully added dispositions for ${this.props.claimantName}.`
      }
    }[this.props.successCode];

    return <Alert title={successObject.title} type="success" lowerMargin>
      {successObject.body}
    </Alert>;
  }
}

export class FlashAlerts extends React.PureComponent {
  render() {
    let alerts = this.props.flash.map((flash, idx) => {
      let flashMsg;

      if (flash[0] === 'success') {
        flashMsg = <Alert key={idx} title="Success!" type="success" >{flash[1]}</Alert>;
      } else if (flash[0] === 'notice') {
        flashMsg = <Alert key={idx} title="Note" type="info" >{flash[1]}</Alert>;
      } else if (flash[0] === 'error') {
        flashMsg = <Alert key={idx} title="Error" type="error" >{flash[1]}</Alert>;
      }

      return flashMsg;
    });

    return <div className="cf-flash-messages">{alerts}</div>;
  }
}
