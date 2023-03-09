import React from 'react';
import PropTypes from 'prop-types';
import Alert from '../../components/Alert';

export class ErrorAlert extends React.PureComponent {
  render() {
    const errorObject = {
      decisionIssueUpdateFailed: {
        title: 'Something went wrong',
        body: 'The dispositions for this task could not be saved.' +
              ' Please try submitting again. If the problem persists, please contact the Caseflow team' +
              ' via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket via YourIT.'
      }
    }[this.props.errorCode];

    return <Alert title={errorObject.title} type="error" lowerMargin>
      {errorObject.body}
    </Alert>;
  }
}

ErrorAlert.propTypes = {
  errorCode: PropTypes.string,
};

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

SuccessAlert.propTypes = {
  claimantName: PropTypes.string,
  successCode: PropTypes.string
};

export class VHAOrgJoinInfoNotice extends React.PureComponent {
  render() {
    const VHAOrgJoinInfoNoticeObject = {
      vhaOrgJoinInfoNotified: {
        title: 'VHA Team Access',
        body: 'If you are a VHA team member, you will need access to VHA-specific' +
        ' pages to perform your duties. Press the “Request access” button below to' +
        ' be redirected to the VHA section within the Help page, where you can' +
        ' submit a form for access.'
      }
    }[this.props.VHAOrgJoinInfoNoticeCode];

    return <Alert title={VHAOrgJoinInfoNoticeObject.title} type="info" lowerMargin>
      {VHAOrgJoinInfoNoticeObject.body}
    </Alert>;
  }
}

VHAOrgJoinInfoNotice.propTypes = {
  VHAOrgJoinInfoNoticeCode: PropTypes.string
};

export class FlashAlerts extends React.PureComponent {
  render() {
    let alerts = this.props.flash.map((flash, idx) => {
      let flashMsg;

      if (flash[0] === 'success') {
        flashMsg = <Alert key={idx} title="Success!" type="success" lowerMargin>{flash[1]}</Alert>;
      } else if (flash[0] === 'notice') {
        flashMsg = <Alert key={idx} title="Note" type="info" lowerMargin>{flash[1]}</Alert>;
      } else if (flash[0] === 'error') {
        flashMsg = <Alert key={idx} title="Error" type="error" lowerMargin>{flash[1]}</Alert>;
      } else if (flash[0] === 'edited') {
        flashMsg = <Alert key={idx} title="Edit Completed" type="success" lowerMargin>{flash[1]}</Alert>;
      } else if (flash[0] === 'show_vha_org_join_info') {
        flashMsg = <Alert key={idx} title="VHA Team Accesss" type="info" lowerMargin> {} </Alert>;
      }

      return flashMsg;
    });

    return <div className="cf-flash-messages">{alerts}</div>;
  }
}

FlashAlerts.propTypes = {
  flash: PropTypes.array
};
