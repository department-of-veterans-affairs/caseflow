import React from 'react';
import Button from '../../components/Button';
import StatusMessage from '../../components/StatusMessage';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { startNewIntake } from '../redux/actions';

export default class Completed extends React.PureComponent {
  render() {
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
    this.props.history.push('/')
  }

  render = () => <Button onClick={this.handleClick}>Begin next intake</Button>
}

export const CompletedNextButton = connect(
  null,
  (dispatch) => bindActionCreators({
    startNewIntake
  }, dispatch)
)(UnconnectedCompletedNextButton)
