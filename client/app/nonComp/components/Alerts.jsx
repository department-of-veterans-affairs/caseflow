import React from 'react';
import PropTypes from 'prop-types';
import Alert from '../../components/Alert';
import { VhaJoinOrgAlert } from '../../queue/membershipRequest/VhaJoinOrgAlert';

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

// method to list MST/PACT edits
const listChanges = (editList) => {
  const divStyle = { margin: '.1rem'};

  return editList.map((value) => <div style={divStyle}><small>{value}</small></div>);
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
      } else if (flash[0] === 'mst_pact_edited') {
        flashMsg = <Alert key={idx} title="You have successfully updated issues on this appeal" type="success" lowerMargin>{listChanges(flash[1])}</Alert>;
      } else if (flash[0] === 'show_vha_org_join_info') {
        flashMsg = <VhaJoinOrgAlert />;
      }

      return flashMsg;
    });

    return <div className="cf-flash-messages">{alerts}</div>;
  }
}

FlashAlerts.propTypes = {
  flash: PropTypes.array
};
