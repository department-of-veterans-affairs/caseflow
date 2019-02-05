import React from 'react';
import { connect } from 'react-redux';

import Button from '../../components/Button';
import { BOA_ADDRESS, DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import Checkbox from '../../components/Checkbox';

class RecordRequestUnconnected extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      isSent: Boolean(this.props.task.closed_at)
    };
  }

  handleSentClick = () => {
    this.setState({ isSent: !this.state.isSent });
  }

  handleSave = () => {
    this.props.handleSave({});
  }

  render = () => {
    const {
      decisionIssuesStatus,
      businessLine,
      task
    } = this.props;

    let completeDiv = null;

    if (!task.closed_at) {
      completeDiv = <React.Fragment>
        <div className="cf-gray-box cf-record-request-checkbox">
          <div className="cf-txt-c">
            <Checkbox
              vertical
              onChange={this.handleSentClick}
              value={this.state.isSent}
              disabled={Boolean(task.closed_at)}
              name="isSent"
              label="I certify this record has been sent to the Board of Veterans' Appeals." />
          </div>
        </div>
        <div className="cf-txt-r">
          <a className="cf-cancel-link" href={`${task.tasks_url}`}>Cancel</a>
          <Button className="usa-button"
            name="submit-update"
            loading={decisionIssuesStatus.update === DECISION_ISSUE_UPDATE_STATUS.IN_PROGRESS}
            disabled={!this.state.isSent} onClick={this.handleSave}>Confirm</Button>
        </div>
      </React.Fragment>;
    }

    return <div>
      <div className="cf-decisions">
        <div className="usa-grid-full">
          <div className="usa-width-one-half">
            <h2>Request to send Veteran record to the Board</h2>
          </div>
        </div>
        <hr />
        <div className="usa-width-full">
          <p>
            The Veteran/appellant has filed a Notice of Disagreement at the Board of Veterans' Appeals.
            In order to decide that appeal, the Board will need the complete records from {businessLine}.
          </p>
          <p>
            Please take necessary steps to send this record to the Board.
          </p>
          <p>
            Mail to <strong>{BOA_ADDRESS}</strong>.
          </p>
        </div>
      </div>
      { completeDiv }
    </div>;
  }
}

const RecordRequest = connect(
  (state) => ({
    appeal: state.appeal,
    businessLine: state.businessLine,
    task: state.task,
    decisionIssuesStatus: state.decisionIssuesStatus
  })
)(RecordRequestUnconnected);

export default RecordRequest;
