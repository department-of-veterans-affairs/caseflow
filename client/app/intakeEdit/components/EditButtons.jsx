import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';
import update from 'immutability-helper';
import pluralize from 'pluralize';

import Button from '../../components/Button';
import IssueCounter from '../../intake/components/IssueCounter';
import { issueCountSelector } from '../../intake/selectors';
import { requestIssuesUpdate } from '../actions/edit';
import { REQUEST_STATE } from '../../intake/constants';
import SaveAlertConfirmModal from './SaveAlertConfirmModal';

class SaveButtonUnconnected extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      originalIssueNumber: this.props.state.addedIssues.length,
      showModals: {
        issueChangeModal: false,
        unidentifiedIssueModal: false
      }
    };
  }

  validate = () => {
    // do validation and show modals
    let showModals = {
      issueChangeModal: false,
      unidentifiedIssueModal: false
    };

    if (this.state.originalIssueNumber !== this.props.state.addedIssues.length) {
      showModals.issueChangeModal = true;
    }

    if (this.props.state.addedIssues.filter((i) => i.isUnidentified).length > 0) {
      showModals.unidentifiedIssueModal = true;
    }

    if (_.every(showModals, (modal) => modal === false)) {
      // no modals are shown, just save
      this.save();
    } else {
      // some modals are shown, need to confirm
      this.setState({
        showModals
      });
    }
  };

  closeModal = (modalToClose, callback) => {
    const updateModal = {};

    updateModal[modalToClose] = { $set: false };
    this.setState({
      showModals: update(this.state.showModals, updateModal)
    }, callback);
  }

  confirmModal = (modalToClose) => {
    this.closeModal(modalToClose, () => {
      // if all modals are now confirmed, save
      if (_.every(this.state.showModals, (modal) => modal === false)) {
        this.save();
      }
    });
  };

  save = () => {
    this.props.requestIssuesUpdate(this.props.claimId, this.props.formType, this.props.state).
      then(() => {
        if (this.props.formType === 'appeal') {
          window.location.href = `/queue/appeals/${this.props.claimId}`;
        } else {
          this.props.history.push('/confirmation');
        }
      });
  }

  render = () => {
    const {
      addedIssues,
      originalIssues,
      issueCount,
      requestStatus
    } = this.props;

    const saveDisabled = _.isEqual(addedIssues, originalIssues) || issueCount === 0;

    return <span>
      { this.state.showModals.issueChangeModal && <SaveAlertConfirmModal
        title="Number of issues has changed"
        onClose={() => this.closeModal('issueChangeModal')}
        onConfirm={() => this.confirmModal('issueChangeModal')}>
        <p>
          The review originally had {this.state.originalIssueNumber}&nbsp;
          { pluralize('issue', this.state.originalIssueNumber) } but now has {this.props.state.addedIssues.length}.
        </p>
        <p>Please check that this is the correct number.</p>
      </SaveAlertConfirmModal>}

      { this.state.showModals.unidentifiedIssueModal && <SaveAlertConfirmModal
        title="Unidentified issue"
        onClose={() => this.closeModal('unidentifiedIssueModal')}
        onConfirm={() => this.confirmModal('unidentifiedIssueModal')}>
        <p>
          You still have an "Unidentified" issue that needs to be&nbsp;
          removed and replaced with a rated or non-rated issue.
        </p>
        <p>Are you sure you want to save this issue without fixing the unidentified issue?</p>
      </SaveAlertConfirmModal>}

      <Button
        name="submit-update"
        onClick={this.validate}
        // on success also keep the loading state
        // appeals take a long time to navigate to a different page, do not allow double saves in the meantime
        // for other review types, this is a no-op since page changes
        loading={requestStatus.requestIssuesUpdate === REQUEST_STATE.IN_PROGRESS ||
          requestStatus.requestIssuesUpdate === REQUEST_STATE.SUCCEEDED}
        disabled={saveDisabled}
      >
        Save
      </Button>
    </span>;
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
    state
  }),
  (dispatch) => bindActionCreators({
    requestIssuesUpdate
  }, dispatch)
)(SaveButtonUnconnected);

class CancelEditButtonUnconnected extends React.PureComponent {
  render = () => {
    return <Button
      id="cancel-edit"
      linkStyling
      willNeverBeLoading
      onClick={
        () => {
          if (this.props.formType === 'appeal') {
            window.location.href = `/queue/appeals/${this.props.claimId}`;
          } else {
            this.props.history.push('/cancel');
          }
        }
      }
    >
      Cancel
    </Button>;
  }
}

const CancelEditButton = connect(
  (state) => ({
    formType: state.formType,
    claimId: state.claimId
  })
)(CancelEditButtonUnconnected);

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
