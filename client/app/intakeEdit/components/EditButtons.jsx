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
import { REQUEST_STATE, VBMS_BENEFIT_TYPES } from '../../intake/constants';
import SaveAlertConfirmModal from './SaveAlertConfirmModal';
import PropTypes from 'prop-types';

class SaveButtonUnconnected extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      originalIssueNumber: this.props.state.addedIssues.length,
      showModals: {
        issueChangeModal: false,
        unidentifiedIssueModal: false,
        reviewRemovedModal: false,
        correctionIssueModal: false
      }
    };
  }

  validate = () => {
    // do validation and show modals
    let showModals = {
      issueChangeModal: false,
      unidentifiedIssueModal: false,
      reviewRemovedModal: false,
      correctionIssueModal: false
    };

    if (this.state.originalIssueNumber !== this.props.state.addedIssues.length) {
      if (this.props.state.addedIssues.length === 0) {
        showModals.reviewRemovedModal = true;
      } else {
        showModals.issueChangeModal = true;
      }
    }

    if (this.props.state.addedIssues.filter((i) => i.isUnidentified).length > 0) {
      showModals.unidentifiedIssueModal = true;
    }

    if (this.props.state.addedIssues.filter((i) => i.correctionType).length > 0) {
      showModals.correctionIssueModal = true;
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

  showCorrectionIssueModal = () => {
    return this.state.showModals.correctionIssueModal &&
      !this.state.showModals.reviewRemovedModal &&
      !this.state.showModals.issueChangeModal &&
      !this.state.showModals.unidentifiedIssueModal;
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
      requestStatus,
      veteranValid,
      processedInCaseflow,
      withdrawalDate,
      receiptDate
    } = this.props;

    const invalidVeteran = !veteranValid && (_.some(
      addedIssues, (issue) => VBMS_BENEFIT_TYPES.includes(issue.benefitType) || issue.ratingIssueReferenceId)
    );

    const withdrawDateError = new Date(withdrawalDate) < new Date(receiptDate) || new Date(withdrawalDate) > new Date();

    const validateWithdrawDateError = withdrawalDate && !withdrawDateError;

    const withdrawDateValid = _.every(
      addedIssues, (issue) => !issue.withdrawalPending
    ) || validateWithdrawDateError;

    const saveDisabled = _.isEqual(
      addedIssues, originalIssues
    ) || invalidVeteran || !withdrawDateValid;

    const withdrawReview = !_.isEmpty(addedIssues) && _.every(
      addedIssues, (issue) => issue.withdrawalPending || issue.withdrawalDate
    );

    const saveButtonText = withdrawReview ? 'Withdraw' : 'Save';

    const removeVbmsCopy = 'This will remove the review and cancel all the End Products associated with it.';

    const removeCaseflowCopy = 'This review and all tasks associated with it will be removed.';

    const originalIssueNumberCopy = `The review originally had ${this.state.originalIssueNumber}
       ${pluralize('issue', this.state.originalIssueNumber)} but now has ${this.props.state.addedIssues.length}.`;

    return <span>
      {this.state.showModals.issueChangeModal && <SaveAlertConfirmModal
        title="Number of issues has changed"
        onClose={() => this.closeModal('issueChangeModal')}
        onConfirm={() => this.confirmModal('issueChangeModal')}>
        <p>
          {originalIssueNumberCopy}
        </p>
        <p>Please check that this is the correct number.</p>
      </SaveAlertConfirmModal>}

      {this.state.showModals.reviewRemovedModal && <SaveAlertConfirmModal
        title="Remove review?"
        buttonText= "Yes, remove"
        onClose={() => this.closeModal('reviewRemovedModal')}
        onConfirm={() => this.confirmModal('reviewRemovedModal')}>
        <p>
          {originalIssueNumberCopy}
        </p>
        <p>{processedInCaseflow ? removeCaseflowCopy : removeVbmsCopy}</p>
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

      { this.showCorrectionIssueModal() && <SaveAlertConfirmModal
        title="Establish 930 EP"
        buttonText= "Yes, establish"
        onClose={() => this.closeModal('correctionIssueModal')}
        onConfirm={() => this.confirmModal('correctionIssueModal')}>
        <p>
          You are now creating a 930 EP in VBMS.</p>
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
        redStyling={withdrawReview}
      >
        { saveButtonText }
      </Button>
    </span>;
  }
}

SaveButtonUnconnected.propTypes = {
  addedIssues: PropTypes.array,
  originalIssues: PropTypes.array,
  requestStatus: PropTypes.object,
  veteranValid: PropTypes.bool,
  processedInCaseflow: PropTypes.bool,
  withdrawalDate: PropTypes.string,
  receiptDate: PropTypes.string,
  requestIssuesUpdate: PropTypes.func,
  formType: PropTypes.string,
  claimId: PropTypes.string,
  history: PropTypes.object,
  state: PropTypes.shape({
    addedIssues: PropTypes.array
  })
};

const SaveButton = connect(
  (state) => ({
    claimId: state.claimId,
    formType: state.formType,
    addedIssues: state.addedIssues,
    originalIssues: state.originalIssues,
    requestStatus: state.requestStatus,
    issueCount: issueCountSelector(state),
    veteranValid: state.veteranValid,
    processedInCaseflow: state.processedInCaseflow,
    withdrawalDate: state.withdrawalDate,
    receiptDate: state.receiptDate,
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

CancelEditButtonUnconnected.propTypes = {
  history: PropTypes.object,
  formType: PropTypes.string,
  claimId: PropTypes.string
};

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

EditButtons.propTypes = {
  history: PropTypes.object
};
