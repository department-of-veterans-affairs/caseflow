import _ from 'lodash';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Button from '../../components/Button';
import IssueCounter from '../../intake/components/IssueCounter';
import { issueCountSelector } from '../../intake/selectors';
import { requestIssuesUpdate } from '../actions/edit'
import { REQUEST_STATE } from '../../intake/constants';

class SaveButtonUnconnected extends React.PureComponent {
  handleClick = () => {
    this.props.requestIssuesUpdate(this.props.claimId, this.props.formType, this.props.state).then(() => this.props.history.push('/confirmation'));
  }

  render = () => {
    const {
      addedIssues,
      originalIssues,
      issueCount,
      requestStatus
    } = this.props;

    const saveDisabled = _.isEqual(addedIssues, originalIssues) || issueCount === 0;

    return <Button
      name="submit-update"
      onClick={this.handleClick}
      loading={this.props.requestStatus.requestIssuesUpdate === REQUEST_STATE.IN_PROGRESS}
      disabled={saveDisabled}
      >
      Save
    </Button>;
  }
}

const SaveButton = connect(
  (state) => ({
    claimId: state.claimId,
    formType: state.formType,
    addedIssues: state.addedIssues,
    originalIssues: state.originalIssues,
    requestStatus: state.requestStatus,
    issueCount: issueCountSelector(state),
    state: state
  }),
  (dispatch) => bindActionCreators({
    requestIssuesUpdate
  }, dispatch)
)(SaveButtonUnconnected);

class CancelEditButton extends React.PureComponent {
  render = () => {
    return <Button
      id="cancel-edit"
      linkStyling
      willNeverBeLoading
      onClick={
        () => {
          this.props.history.push('/cancel');
        }
      }
    >
      Cancel edit
    </Button>;
  }
}

const mapStateToProps = (state) => {
  return {
    issueCount: issueCountSelector(state)
  };
};

const IssueCounterConnected = connect(mapStateToProps)(IssueCounter);

export default class EditButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelEditButton history={this.props.history} />
      <SaveButton history={this.props.history} />
      <IssueCounterConnected />
    </div>
}
