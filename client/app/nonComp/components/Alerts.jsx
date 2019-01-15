import React from 'react';
import Alert from '../../components/Alert';
import _ from 'lodash';

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
    if (!this.props.flash) {
      return <div></div>;
    }

    let alerts = _.map(this.props.flash, (flash, idx) => {
      if (flash[0] === 'notice') {
        return <Alert key={idx} title="Success!" type="success" lowerMargin>{flash[1]}</Alert>;
      }
    });

    return <div>{alerts}</div>;
  }
}
