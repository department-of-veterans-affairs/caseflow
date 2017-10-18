import React from 'react';
import Button from '../../components/Button';
import BareOrderedList from '../../components/BareOrderedList';
import CancelButton from '../components/CancelButton';
import { Redirect } from 'react-router-dom';
import { REQUEST_STATE, PAGE_PATHS, RAMP_INTAKE_STATES } from '../constants';
import { connect } from 'react-redux';
import { completeIntake } from '../redux/actions';
import { bindActionCreators } from 'redux';
import { getRampElectionStatus } from '../redux/selectors';

class Finish extends React.PureComponent {
  render() {
    switch (this.props.rampElectionStatus) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN}/>;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW}/>;
    case RAMP_INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED}/>;
    default:
    }

    let epName, optionName;

    if (this.props.rampElection.optionSelected === 'supplemental_claim') {
      optionName = 'Supplemental Claim';
      epName = '683 RAMP – Supplemental Claim Review Rating';
    } else {
      optionName = 'Higher-Level Review';
      epName = '682 RAMP – Higher Level Review Rating';
    }

    const steps = [
      <span>Upload the RAMP Election form to the VBMS eFolder and ensure the Document Type is <b>Correspondence</b>.</span>,
      <span>Update the Subject Line with "Ramp Election."</span>,
      <span>Create an EP <strong>{ epName }</strong> in VBMS.</span>,
      <span>Add a placeholder contention of "RAMP."</span>,
      <span>Send a RAMP Withdrawal Letter using Letter Creator.</span>
    ];
    const stepFns = steps.map((step, index) =>
      () => <span><strong>Step {index}.</strong> {step}</span>
    );

    return <div>
      <h1>Finish processing { optionName } election</h1>
      <p>Please complete the following 4 steps outside Caseflow.</p>
      <BareOrderedList className="cf-steps-outside-of-caseflow-list" items={stepFns} />
    </div>;
  }
}

class FinishNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.completeIntake(this.props.rampElection).then(
      () => this.props.history.push('/completed')
    );
  }

  render = () =>
    <Button
      name="submit-review"
      onClick={this.handleClick}
      loading={this.props.requestState === REQUEST_STATE.IN_PROGRESS}
      legacyStyling={false}
    >
      { "I've completed all the steps" }
    </Button>;
}

const FinishNextButtonConnected = connect(
  ({ rampElection, requestStatus }) => ({
    requestState: requestStatus.completeIntake,
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
    rampElection: state.rampElection,
    rampElectionStatus: getRampElectionStatus(state)
  })
)(Finish);
