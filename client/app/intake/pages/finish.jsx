import React from 'react';
import Button from '../../components/Button';
import BareOrderedList from '../../components/BareOrderedList';
import CancelButton from '../components/CancelButton';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, RAMP_INTAKE_STATES } from '../constants';
import { connect } from 'react-redux';
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

    const steps = [
      <span>Upload the RAMP election form to VBMS and ensure the Document Type is <em>Correspondence</em>.</span>,
      <span>Update the Subject Line with <em>RAMP Opt-In</em>.</span>,
      <span>Create an EP <strong>030 RAMP Supplemental</strong> in VBMS.</span>,
      <span>Add a placeholder contention of <em>RAMP</em>.</span>
    ];
    const stepFns = steps.map((step, index) => () => <span><strong>Step {index}.</strong> {step}</span>);

    return <div>
      <h1>Finish processing Supplemental Claim request</h1>
      <p>Please complete the following 4 steps outside Caseflow.</p>
      <BareOrderedList className="cf-steps-outside-of-caseflow-list" items={stepFns} />
    </div>;
  }
}

class FinishNextButton extends React.PureComponent {
  handleClick = () => this.props.history.push('/completed');

  render = () => <Button onClick={this.handleClick} legacyStyling={false}>I've completed all the steps</Button>;
}

export class FinishButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
      <FinishNextButton history={this.props.history} />
    </div>
}

export default connect(
  (state) => ({
    rampElection: state.rampElection,
    rampElectionStatus: getRampElectionStatus(state)
  })
)(Finish);
