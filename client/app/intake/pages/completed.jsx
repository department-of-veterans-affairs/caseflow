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
    switch (this.props.rampElectionStatus) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN}/>;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW}/>;
    // TODO: uncomment when complete logic is done
    // case RAMP_INTAKE_STATES.REVIEWED:
    //  return <Redirect to={PAGE_PATHS.FINISH}/>;
    default:
    }

    const message = 'Joe Snuffy\'s (ID #222222222) opt-in request has been processed, ' +
      'and Caseflow closed the record in VACOLS. You can now begin processing the next opt-in letter.';

    return <div>
      <StatusMessage
        title="Intake completed"
        type="success"
        wrapInAppSegment={false}
        messageText={message}
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
    rampElectionStatus: getRampElectionStatus(state)
  })
)(Completed);
