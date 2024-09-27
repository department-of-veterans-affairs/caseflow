import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';
import update from 'immutability-helper';
import pluralize from 'pluralize';
import PropTypes from 'prop-types';

import Button from '../../components/Button';
import IssueCounter from '../../intake/components/IssueCounter';
import { getOpenPendingIssueModificationRequests, issueCountSelector } from '../../intake/selectors';
import { requestIssuesUpdate } from '../actions/edit';
import { REQUEST_STATE, VBMS_BENEFIT_TYPES } from '../../intake/constants';
import SaveAlertConfirmModal from './SaveAlertConfirmModal';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';
import SPECIALTY_CASE_TEAM_BENEFIT_TYPES from 'constants/SPECIALTY_CASE_TEAM_BENEFIT_TYPES';

class SaveButtonUnconnected extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      originalIssueNumber: this.props.state.addedIssues.length,
      showModals: {
        issueChangeModal: false,
        unidentifiedIssueModal: false,
        reviewRemovedModal: false,
        correctionIssueModal: false,
        moveToSctModal: false,
        moveToDistributionModal: false
      }
    };
  }

  validate = () => {
    // do validation and show modals

    let showModals = {
      issueChangeModal: false,
      unidentifiedIssueModal: false,
      reviewRemovedModal: false,
      correctionIssueModal: false,
      moveToSctModal: false,
      moveToDistributionModal: false
    };

    // Specialty Case Team (SCT) logic for movement of appeals based on additional and removal of SCT request issues
    const specialtyCaseTeamBenefitTypes = Object.keys(SPECIALTY_CASE_TEAM_BENEFIT_TYPES);
    const addedIssuesHasSCTIssue = this.props.state.addedIssues.some((issue) =>
      specialtyCaseTeamBenefitTypes.includes(issue.benefitType) && !issue.withdrawalPending);
    const originalIssuesHasSCTIssue = this.props.originalIssues.some((issue) =>
      specialtyCaseTeamBenefitTypes.includes(issue.benefitType));
    const hasDistributionTaskAndSCTFeatureToggle = this.props.hasDistributionTask &&
     this.props.specialtyCaseTeamDistribution;

    if (addedIssuesHasSCTIssue && !originalIssuesHasSCTIssue && hasDistributionTaskAndSCTFeatureToggle) {
      showModals.moveToSctModal = true;
    }

    if (!addedIssuesHasSCTIssue && originalIssuesHasSCTIssue && hasDistributionTaskAndSCTFeatureToggle &&
        this.props.hasSpecialtyCaseTeamAssignTask) {
      showModals.moveToDistributionModal = true;
    }

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
      !this.state.showModals.unidentifiedIssueModal &&
      !this.state.showModals.moveToSctModal;
  }

  showMoveToSctModal = () => {
    if (!this.props.specialtyCaseTeamDistribution) {
      return false;
    }

    return this.state.showModals.moveToSctModal &&
      !this.state.showModals.reviewRemovedModal &&
      !this.state.showModals.issueChangeModal &&
      !this.state.showModals.unidentifiedIssueModal &&
      !this.state.showModals.correctionIssueModal;
  }

  showMoveToDistributionModal = () => {
    if (!this.props.specialtyCaseTeamDistribution) {
      return false;
    }

    return this.state.showModals.moveToDistributionModal &&
      !this.state.showModals.reviewRemovedModal &&
      !this.state.showModals.issueChangeModal &&
      !this.state.showModals.unidentifiedIssueModal &&
      !this.state.showModals.correctionIssueModal &&
      !this.state.showModals.moveToSctModal;
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
      benefitType,
      pendingIssueModificationRequests,
      originalPendingIssueModificationRequests,
      isRemand,
      openIssueModificationRequests
    } = this.props;

    const invalidVeteran = !veteranValid && (_.some(
      addedIssues, (issue) => VBMS_BENEFIT_TYPES.includes(issue.benefitType) || issue.ratingIssueReferenceId)
    );

    const withdrawDateError = new Date(withdrawalDate) < new Date(receiptDate) || new Date(withdrawalDate) > new Date();

    const validateWithdrawDateError = withdrawalDate && !withdrawDateError;

    const withdrawDateValid = _.every(
      addedIssues, (issue) => !issue.withdrawalPending
    ) || validateWithdrawDateError;

    const withdrawReview = !_.isEmpty(addedIssues) && _.every(
      addedIssues, (issue) => issue.withdrawalPending || issue.withdrawalDate
    );

    const hasPendingAdditionRequests = openIssueModificationRequests.some((issueModificationRequest) => {
      return issueModificationRequest.requestType === 'addition';
    }) && (_.isEmpty(addedIssues) || withdrawReview);

    const saveDisabled = (_.isEqual(addedIssues, originalIssues) &&
       _.isEqual(pendingIssueModificationRequests, originalPendingIssueModificationRequests)) ||
      invalidVeteran ||
      !withdrawDateValid || hasPendingAdditionRequests || isRemand;

    let saveButtonText;

    if (benefitType === 'vha' && _.every(addedIssues, (issue) => (
      issue.withdrawalDate || issue.withdrawalPending) || issue.decisionDate
    ) && _.isEmpty(openIssueModificationRequests)) {
      saveButtonText = withdrawReview ? COPY.CORRECT_REQUEST_ISSUES_WITHDRAW : COPY.CORRECT_REQUEST_ISSUES_ESTABLISH;
    } else {
      saveButtonText = withdrawReview ? COPY.CORRECT_REQUEST_ISSUES_WITHDRAW : COPY.CORRECT_REQUEST_ISSUES_SAVE;
    }

    const originalIssueNumberCopy = sprintf(COPY.CORRECT_REQUEST_ISSUES_ORIGINAL_NUMBER, this.state.originalIssueNumber,
      pluralize('issue', this.state.originalIssueNumber), this.props.state.addedIssues.length);

    const removeReviewBody = processedInCaseflow ?
      <React.Fragment>
        <p>{COPY.CORRECT_REQUEST_ISSUES_REMOVE_CASEFLOW_TEXT}</p>
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

      { this.showMoveToSctModal() && <SaveAlertConfirmModal
        title={COPY.MOVE_TO_SCT_MODAL_TITLE}
        buttonText={COPY.MODAL_MOVE_BUTTON}
        onClose={() => this.closeModal('moveToSctModal')}
        onConfirm={() => this.confirmModal('moveToSctModal')} >
        <p>{COPY.MOVE_TO_SCT_MODAL_BODY}</p>
      </SaveAlertConfirmModal>}

      { this.showMoveToDistributionModal() && <SaveAlertConfirmModal
        title={COPY.MOVE_TO_DISTRIBUTION_MODAL_TITLE}
        buttonText={COPY.MODAL_MOVE_BUTTON}
        onClose={() => this.closeModal('moveToDistributionModal')}
        onConfirm={() => this.confirmModal('moveToDistributionModal')} >
        <p>{COPY.MOVE_TO_DISTRIBUTION_MODAL_BODY}</p>
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
  hasDistributionTask: PropTypes.bool,
  hasSpecialtyCaseTeamAssignTask: PropTypes.bool,
  specialtyCaseTeamDistribution: PropTypes.bool,
  pendingIssueModificationRequests: PropTypes.array,
  originalPendingIssueModificationRequests: PropTypes.array,
  isRemand: PropTypes.bool,
  openIssueModificationRequests: PropTypes.array,
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
    hasDistributionTask: state.hasDistributionTask,
    hasSpecialtyCaseTeamAssignTask: state.hasSpecialtyCaseTeamAssignTask,
    specialtyCaseTeamDistribution: state.featureToggles.specialtyCaseTeamDistribution,
    pendingIssueModificationRequests: state.pendingIssueModificationRequests,
    openIssueModificationRequests: getOpenPendingIssueModificationRequests(state),
    isRemand: state.isRemand,
    originalPendingIssueModificationRequests: state.originalPendingIssueModificationRequests,
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
