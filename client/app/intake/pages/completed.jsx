import React from 'react';
import Button from '../../components/Button';
import StatusMessage from '../../components/StatusMessage';

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

export class CompletedNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.history.push('/');
  }

  render() {
    return <Button onClick={this.handleClick}>Begin next intake</Button>;
  }
}
