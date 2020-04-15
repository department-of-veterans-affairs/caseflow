import React from 'react';
import Button from '../../../components/Button';
import BareList from '../../../components/BareList';
import CancelButton from '../../components/CancelButton';
import Checkbox from '../../../components/Checkbox';
import Alert from '../../../components/Alert';
import Table from '../../../components/Table';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, INTAKE_STATES, REQUEST_STATE } from '../../constants';
import { connect } from 'react-redux';
import { completeIntake, confirmFinishIntake } from '../../actions/rampElection';
import { bindActionCreators } from 'redux';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';
import _ from 'lodash';

const submitText = 'Finish intake';

class Finish extends React.PureComponent {
  getIssuesAlertContent = (appeals) => {
    const issueColumns = [
      {
        header: 'Program',
        valueName: 'programDescription'
      },
      {
        header: 'VACOLS Issues',
        valueFunction: (issue, index) => (
          issue.description.map(
            (descriptor) => <div key={`${descriptor}-${index}`}>{descriptor}</div>
          )
        )
      },
      {
        header: 'Note',
        valueName: 'note'
      }
    ];

    return _.map(appeals, (appeal) => (
      <Table
        key={appeal.id}
        columns={issueColumns}
        rowObjects={appeal.issues}
        slowReRendersAreOk
        summary="Appeal issues"
      />
    ));
  }

  render() {
    const {
      optionSelected,
      rampElectionStatus,
      appeals,
      requestState,
      finishConfirmed,
      finishConfirmedError,
      completeIntakeErrorCode,
      completeIntakeErrorData
    } = this.props;

    switch (rampElectionStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    let optionName;

    if (optionSelected === 'supplemental_claim') {
      optionName = 'Supplemental Claim';
    } else {
      optionName = 'Higher-Level Review';
    }

    const steps = [
      <span>
        Upload the RAMP Election form to the VBMS eFolder and ensure the
        Document Type is <b>RAMP Opt-in Election</b>.
      </span>,
      <span>Update the Subject Line with <b>RAMP Election</b>.</span>
    ];
    const stepFns = steps.map((step, index) =>
      () => <span><strong>Step {index + 1}.</strong> {step}</span>
    );

    const issuesAlertTitle = `This Veteran has ${appeals.length} ` +
                             `eligible ${appeals.length === 1 ? 'appeal' : 'appeals'}` +
                             ', with the following issues';

    return <div>
      <h1>Finish processing { optionName } election</h1>

      { requestState === REQUEST_STATE.FAILED &&
        <ErrorAlert
          errorCode={completeIntakeErrorCode}
          errorData={completeIntakeErrorData} />
      }

      <p>Please complete the following steps outside Caseflow.</p>
      <BareList items={stepFns} />

      <Alert title={issuesAlertTitle} type="info">
        { this.getIssuesAlertContent(appeals) }
      </Alert>

      <Checkbox
        label="I've completed the above steps outside Caseflow."
        name="confirm-finish"
        required
        value={finishConfirmed}
        onChange={this.props.confirmFinishIntake}
        errorMessage={finishConfirmedError}
      />
    </div>;
  }
}

class FinishNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.completeIntake(this.props.intakeId, this.props.rampElection).then(
      (completeWasSuccessful) => {
        if (completeWasSuccessful) {
          this.props.history.push('/completed');
        }
      }
    );
  }

  render = () =>
    <Button
      name="submit-review"
      onClick={this.handleClick}
      loading={this.props.requestState === REQUEST_STATE.IN_PROGRESS}
    >
      { submitText }
    </Button>;
}

const FinishNextButtonConnected = connect(
  ({ rampElection, intake }) => ({
    requestState: rampElection.requestStatus.completeIntake,
    intakeId: intake.id,
    rampElection
  }),
  (dispatch) => bindActionCreators({
    completeIntake
  }, dispatch)
)(FinishNextButton);

export class FinishButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
      <FinishNextButtonConnected history={this.props.history} />
    </div>
}

export default connect(
  (state) => ({
    optionSelected: state.rampElection.optionSelected,
    finishConfirmed: state.rampElection.finishConfirmed,
    finishConfirmedError: state.rampElection.finishConfirmedError,
    rampElectionStatus: getIntakeStatus(state),
    appeals: state.rampElection.appeals,
    requestState: state.rampElection.requestStatus.completeIntake,
    completeIntakeErrorCode: state.rampElection.requestStatus.completeIntakeErrorCode,
    completeIntakeErrorData: state.rampElection.requestStatus.completeIntakeErrorData
  }),
  (dispatch) => bindActionCreators({
    confirmFinishIntake
  }, dispatch)
)(Finish);
