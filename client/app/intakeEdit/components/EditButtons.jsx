import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';
import update from 'immutability-helper';
import pluralize from 'pluralize';
import PropTypes from 'prop-types';

import Button from '../../components/Button';
import IssueCounter from '../../intake/components/IssueCounter';
import { issueCountSelector } from '../../intake/selectors';
import { requestIssuesUpdate } from '../actions/edit';
import { REQUEST_STATE, VBMS_BENEFIT_TYPES } from '../../intake/constants';
import SaveAlertConfirmModal from './SaveAlertConfirmModal';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';

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
      receiptDate,
      benefitType
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

    let saveButtonText;

    if (benefitType === 'vha' && _.every(addedIssues, (issue) => issue.decisionDate)) {
      saveButtonText = 'Establish';
    } else {
      saveButtonText = withdrawReview ? COPY.CORRECT_REQUEST_ISSUES_WITHDRAW : COPY.CORRECT_REQUEST_ISSUES_SAVE;
    }

    const originalIssueNumberCopy = sprintf(COPY.CORRECT_REQUEST_ISSUES_ORIGINAL_NUMBER, this.state.originalIssueNumber,
      pluralize('issue', this.state.originalIssueNumber), this.props.state.addedIssues.length);

    const removeReviewBody = processedInCaseflow ?
      <React.Fragment>
        <p>{COPY.CORRECT_REQUEST_ISSUES_REMOVE_CASEFLOW_TEXT}</p>
        <p>{COPY.CORRECT_REQUEST_ISSUES_REMOVE_CASEFLOW_TEXT_CONFIRM}</p>
      </React.Fragment> :
      <React.Fragment><p>{COPY.CORRECT_REQUEST_ISSUES_REMOVE_VBMS_TEXT}</p></React.Fragment>;

    return <span>
      {this.state.showModals.issueChangeModal && <SaveAlertConfirmModal
        title={COPY.CORRECT_REQUEST_ISSUES_CHANGED_MODAL_TITLE}
        onClose={() => this.closeModal('issueChangeModal')}
        onConfirm={() => this.confirmModal('issueChangeModal')}>
        <p>
          {originalIssueNumberCopy}
        </p>
        <p>{COPY.CORRECT_REQUEST_ISSUES_CHANGED_MODAL_TEXT}</p>
      </SaveAlertConfirmModal>}

      {this.state.showModals.reviewRemovedModal && <SaveAlertConfirmModal
        title={processedInCaseflow ?
          COPY.CORRECT_REQUEST_ISSUES_REMOVE_CASEFLOW_TITLE :
          COPY.CORRECT_REQUEST_ISSUES_REMOVE_VBMS_TITLE}
        buttonText={COPY.CORRECT_REQUEST_ISSUES_REMOVE_MODAL_BUTTON}
        onClose={() => this.closeModal('reviewRemovedModal')}
        onConfirm={() => this.confirmModal('reviewRemovedModal')}
        icon="warning">
        <p>{originalIssueNumberCopy}</p>
        {removeReviewBody}
      </SaveAlertConfirmModal>}

      { this.state.showModals.unidentifiedIssueModal && <SaveAlertConfirmModal
        title="Unidentified issue"
        onClose={() => this.closeModal('unidentifiedIssueModal')}
        onConfirm={() => this.confirmModal('unidentifiedIssueModal')}>
        <p>{COPY.CORRECT_REQUEST_ISSUES_UNIDENTIFIED_MODAL_TEXT}</p>
        <p>{COPY.CORRECT_REQUEST_ISSUES_UNIDENTIFIED_MODAL_TEXT_CONFIRM}</p>
      </SaveAlertConfirmModal>}

      { this.showCorrectionIssueModal() && <SaveAlertConfirmModal
        title={COPY.CORRECT_REQUEST_ISSUES_ESTABLISH_MODAL_TITLE}
        buttonText= {COPY.CORRECT_REQUEST_ISSUES_ESTABLISH_MODAL_BUTTON}
        onClose={() => this.closeModal('correctionIssueModal')}
        onConfirm={() => this.confirmModal('correctionIssueModal')}>
        <p>{COPY.CORRECT_REQUEST_ISSUES_ESTABLISH_MODAL_TEXT}</p>
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
  benefitType: PropTypes.string,
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
    benefitType: state.benefitType,
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
