import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import { withRouter } from 'react-router-dom';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';

import { COLORS } from '../constants/AppConstants';
import { TitleDetailsSubheader } from '../components/TitleDetailsSubheader';
import { TitleDetailsSubheaderSection } from '../components/TitleDetailsSubheaderSection';
import {
  appealWithDetailSelector,
  legacyJudgeTasksAssignedToUser,
  legacyAttorneyTasksAssignedByUser
} from './selectors';
import { pencilSymbol, clockIcon } from '../components/RenderFunctions';
import { renderLegacyAppealType } from './utils';
import { requestPatch } from './uiReducer/uiActions';
import Button from '../components/Button';
import COPY from '../../COPY';
import CopyTextButton from '../components/CopyTextButton';
import DocketTypeBadge from './../components/DocketTypeBadge';
import Modal from '../components/Modal';
import ReaderLink from './ReaderLink';
import TextField from '../components/TextField';

const editButton = css({
  float: 'right',
  marginLeft: '0.5rem'
});

const overtimeButton = css({
  padding: '0rem'
});

const overtimeLink = css({
  display: 'inline-block'
});

const docketBadgeContainerStyle = css({
  border: '1px',
  borderStyle: 'solid',
  borderColor: COLORS.GREY_LIGHT,
  padding: '0.5rem 1rem 0.5rem 0.5rem',
  margin: '-0.75rem 0',
  backgroundColor: COLORS.WHITE
});

export class CaseTitleDetails extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      showModal: false,
      value: '',
      showError: false,
      documentIdError: ''
    };
  }

  handleModalClose = () => {
    this.setState({
      showModal: !this.state.showModal,
      highlightModal: false,
      documentIdError: ''
    });
  };

  changeButtonState = (value) => {
    this.setState({
      value
    });
  };

  submitForm = (reviewId, legacy) => () => {
    const payload = {
      data: {
        document_id: this.state.value,
        legacy,
        review_id: reviewId
      }
    };

    this.props.
      requestPatch(`/case_reviews/${reviewId}`, payload, { title: 'Document Id Saved!' }).
      then(() => {
        this.handleModalClose();
        window.location.reload();
      }).
      catch((error) => {
        const documentIdErrors = JSON.parse(error.message).errors;

        const documentIdErrorText = documentIdErrors && documentIdErrors[0].detail;

        this.setState({
          highlightModal: true,
          documentIdError: documentIdErrorText,
          value: ''
        });
      });
  };

  changeRoute = () => {
    const { history, appealId } = this.props;

    history.push(`/queue/appeals/${appealId}/modal/set_overtime_status`);
  };

  render = () => {
    const {
      appeal,
      appealId,
      redirectUrl,
      taskType,
      userIsVsoEmployee,
      featureToggles,
      legacyJudgeTasks,
      legacyAttorneyTasks,
      userCssId,
      userRole
    } = this.props;

    const { highlightModal, documentIdError } = this.state;

    // eslint-disable-next-line camelcase
    const userIsAssignedAmaJudge = appeal?.assignedJudge?.css_id === userCssId;
    // is there a legacy judge task assigned to the user or legacy attorney task assigned by the user
    const relevantLegacyTasks = legacyJudgeTasks.concat(legacyAttorneyTasks);

    const showOvertimeButton = userRole === 'Judge' && (relevantLegacyTasks.length > 0 || userIsAssignedAmaJudge);

    // for ama appeal, use docket name, for legacy appeal docket name is always legacy so
    // we need to check if the request type is any of threee :central, video, travel or null
    const showHearingRequestType = appeal?.docketName === 'hearing' ||
      (appeal?.docketName === 'legacy' && appeal?.readableHearingRequestType);

    return (
      <TitleDetailsSubheader id="caseTitleDetailsSubheader">
        <TitleDetailsSubheaderSection title={COPY.TASK_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL}>
          <span {...docketBadgeContainerStyle}>
            <DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />
            {appeal.docketNumber}
          </span>
        </TitleDetailsSubheaderSection>

        {!userIsVsoEmployee && this.props.userCanAccessReader && (
          <TitleDetailsSubheaderSection title={COPY.TASK_SNAPSHOT_ABOUT_BOX_DOCUMENTS_LABEL}>
            <ReaderLink
              appealId={appealId}
              analyticsSource="queue_task"
              redirectUrl={redirectUrl}
              appeal={appeal}
              taskType={taskType}
              docCountWithinLink
              newDocsIcon
            />
          </TitleDetailsSubheaderSection>
        )}

        <TitleDetailsSubheaderSection title={COPY.TASK_SNAPSHOT_ABOUT_BOX_TYPE_LABEL}>
          {renderLegacyAppealType({
            aod: appeal.isAdvancedOnDocket,
            type: appeal.caseType
          })}

          {!appeal.isLegacyAppeal && this.props.canEditAod && (
            <span {...editButton}>
              <Link to={`/queue/appeals/${appeal.externalId}/modal/advanced_on_docket_motion`}>Edit</Link>
            </span>
          )}
        </TitleDetailsSubheaderSection>

        {showHearingRequestType && (
          <TitleDetailsSubheaderSection title={COPY.TASK_SNAPSHOT_ABOUT_BOX_HEARING_REQUEST_TYPE_LABEL}>
            {appeal.readableHearingRequestType ?? ''}
          </TitleDetailsSubheaderSection>
        )}

        {!userIsVsoEmployee && appeal && appeal.documentID && (
          <TitleDetailsSubheaderSection title={COPY.TASK_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}>
            <div id="document-id">
              <CopyTextButton
                text={this.state.value || appeal.documentID}
                label={COPY.TASK_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}
              />
              {appeal.canEditDocumentId && (
                <Button linkStyling onClick={this.handleModalClose}>
                  <span {...css({ position: 'absolute' })}>{pencilSymbol()}</span>
                  <span {...css({ marginRight: '5px', marginLeft: '20px' })}>Edit</span>
                </Button>
              )}
            </div>
            {this.state.showModal && (
              <Modal
                buttons={[
                  { classNames: ['cf-modal-link', 'cf-btn-link'], name: 'Cancel', onClick: this.handleModalClose },
                  {
                    classNames: ['usa-button'],
                    name: 'Save',
                    disabled: !this.state.value || this.state.value === appeal.documentID,
                    onClick: this.submitForm(appeal.caseReviewId, appeal.isLegacyAppeal)
                  }
                ]}
                closeHandler={this.handleModalClose}
                title={COPY.TASK_SNAPSHOT_EDIT_DOCUMENT_ID_MODAL_TITLE}
              >
                <TextField
                  errorMessage={highlightModal ? documentIdError : null}
                  name={COPY.TASK_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}
                  value={this.state.value || appeal.documentID}
                  onChange={this.changeButtonState}
                  autoComplete="off"
                  required
                />
              </Modal>
            )}
          </TitleDetailsSubheaderSection>
        )}

        {!userIsVsoEmployee && appeal.assignedJudge && !appeal.removed && appeal.status !== 'cancelled' && (
          <TitleDetailsSubheaderSection title={COPY.TASK_SNAPSHOT_ASSIGNED_JUDGE_LABEL}>
            {appeal.assignedJudge.full_name}
          </TitleDetailsSubheaderSection>
        )}

        {!userIsVsoEmployee && appeal.assignedAttorney && !appeal.removed && appeal.status !== 'cancelled' && (
          <TitleDetailsSubheaderSection title={COPY.TASK_SNAPSHOT_ASSIGNED_ATTORNEY_LABEL}>
            {appeal.assignedAttorney.full_name}
          </TitleDetailsSubheaderSection>
        )}
        {featureToggles.overtime_revamp && showOvertimeButton && (
          <TitleDetailsSubheaderSection title={COPY.TASK_SNAPSHOT_OVERTIME_LABEL}>
            <Button linkStyling styling={overtimeButton} onClick={this.changeRoute}>
              <span>{clockIcon()}</span>
              <span {...overtimeLink}>
                &nbsp;{appeal.overtime ? COPY.TASK_SNAPSHOT_IS_OVERTIME : COPY.TASK_SNAPSHOT_IS_NOT_OVERTIME}
              </span>
            </Button>
          </TitleDetailsSubheaderSection>
        )}
      </TitleDetailsSubheader>
    );
  };
}

CaseTitleDetails.propTypes = {
  appeal: PropTypes.object.isRequired,
  appealId: PropTypes.string.isRequired,
  canEditAod: PropTypes.bool,
  featureToggles: PropTypes.object,
  history: PropTypes.object,
  redirectUrl: PropTypes.string,
  requestPatch: PropTypes.func.isRequired,
  taskType: PropTypes.string,
  userIsVsoEmployee: PropTypes.bool.isRequired,
  userCanAccessReader: PropTypes.bool,
  userRole: PropTypes.string,
  userCssId: PropTypes.string,
  taskCssId: PropTypes.object,
  resetDecisionOptions: PropTypes.func,
  stageAppeal: PropTypes.func,
  legacyJudgeTasks: PropTypes.object,
  legacyAttorneyTasks: PropTypes.object
};

const mapStateToProps = (state, ownProps) => {
  const { userRole, userCssId, canEditAod, featureToggles, userIsVsoEmployee } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    legacyJudgeTasks: legacyJudgeTasksAssignedToUser(state),
    legacyAttorneyTasks: legacyAttorneyTasksAssignedByUser(state),
    userRole,
    userCssId,
    canEditAod,
    featureToggles,
    userIsVsoEmployee
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      requestPatch
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CaseTitleDetails)
);
