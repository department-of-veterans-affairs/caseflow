import React from 'react';
import Button from '../../components/Button';
import StatusMessage from '../../components/StatusMessage';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { startNewIntake } from '../redux/actions';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, RAMP_INTAKE_STATES } from '../constants';
import { getRampElectionStatus } from '../redux/selectors';

class Completed extends React.PureComponent {
  render() {
    const {
      veteran, rampElection
    } = this.props;

    switch (this.props.rampElectionStatus) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN}/>;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW}/>;
    case RAMP_INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH}/>;
    default:
    }

    const message = `${veteran.name}'s (ID #${veteran.fileNumber}) ` +
      'opt-in request has been processed. You can now begin intake for the next opt-in letter.';

    return <div>
      <StatusMessage
        title="Intake completed"
        type="success"
        leadMessageList={[message]}
        checklist={['Caseflow closed the VACOLS record']}
        wrapInAppSegment={false}
      />
    </div>;
  }
}

class UnconnectedCompletedNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.startNewIntake();
    this.props.history.push('/');
  }

  render = () => <Button onClick={this.handleClick} legacyStyling={false}>Begin next intake</Button>
}

export const CompletedNextButton = connect(
  null,
  (dispatch) => bindActionCreators({
    startNewIntake
  }, dispatch)
)(UnconnectedCompletedNextButton);

export default connect(
  (state) => ({
    rampElection: state.rampElection,
    veteran: state.veteran,
    rampElectionStatus: getRampElectionStatus(state)
  })
)(Completed);
