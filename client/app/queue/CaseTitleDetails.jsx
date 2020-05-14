import { css } from 'glamor';
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import Modal from '../components/Modal';
import TextField from '../components/TextField';
import Button from '../components/Button';
import { bindActionCreators } from 'redux';

import {
  appealWithDetailSelector,
  tasksByAddedByCssIdSelector
} from './selectors';
import DocketTypeBadge from './../components/DocketTypeBadge';
import CopyTextButton from '../components/CopyTextButton';
import ReaderLink from './ReaderLink';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { pencilSymbol, clockIcon } from '../components/RenderFunctions';

import COPY from '../../COPY';
import { COLORS } from '../constants/AppConstants';
import { renderLegacyAppealType } from './utils';
import { requestPatch } from './uiReducer/uiActions';

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

const containingDivStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  display: 'block',
  padding: '0 0 0 2rem',

  '& > *': {
    display: 'inline-block',
    margin: '0'
  }
});

const listStyling = css({
  listStyleType: 'none',
  verticalAlign: 'super',
  display: 'flex',
  flexWrap: 'wrap',
  padding: '1rem 0 0 0'
});

const listItemStyling = css({
  display: 'inline',
  float: 'left',
  padding: '0.5rem 1.5rem 0.5rem 0',
  ':not(:last-child)': {
    '& > div': {
      borderRight: `1px solid ${COLORS.GREY_LIGHT}`
    },
    '& > *': {
      paddingRight: '1.5rem'
    }
  },
  '& > h4': { textTransform: 'uppercase' }
});

const docketBadgeContainerStyle = css({
  border: '1px',
  borderStyle: 'solid',
  borderColor: COLORS.GREY_LIGHT,
  padding: '0.5rem 1rem 0.5rem 0.5rem',
  margin: '-0.75rem 0',
  backgroundColor: COLORS.WHITE
});

const CaseDetailTitleScaffolding = (props) => <div {...containingDivStyling}>
  <ul {...listStyling}>
    {props.children.map((child, i) => child && <li key={i} {...listItemStyling}>{child}</li>)}
  </ul>
</div>;

CaseDetailTitleScaffolding.propTypes = { children: PropTypes.node.isRequired };

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
  }

  changeButtonState = (value) => {
    this.setState({
      value
    });
  }

  submitForm = (reviewId, legacy) => () => {
    const payload = {
      data: {
        document_id: this.state.value,
        legacy,
        review_id: reviewId
      }
    };

    this.props.requestPatch(`/case_reviews/${reviewId}`, payload, { title: 'Document Id Saved!' }).
      then(() => {
        this.handleModalClose();
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
  }

  changeRoute = () => {
    const {
      history,
      appealId
    } = this.props;

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
      task,
      userCssId,
      userRole
    } = this.props;

    const {
      highlightModal,
      documentIdError
    } = this.state;

    const showOvertimeButton = (((task[0]?.addedByCssId === userCssId) &&
    // eslint-disable-next-line camelcase
    userRole === 'Judge') || (appeal?.assignedJudge?.css_id === userCssId)) && true;

    return <CaseDetailTitleScaffolding>
      <React.Fragment>
        <h4>{COPY.TASK_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL}</h4>
        <div>
          <span {...docketBadgeContainerStyle}>
            <DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />{appeal.docketNumber}
          </span>
        </div>
      </React.Fragment>

      { !userIsVsoEmployee && this.props.userCanAccessReader &&
        <React.Fragment>
          <h4>{COPY.TASK_SNAPSHOT_ABOUT_BOX_DOCUMENTS_LABEL}</h4>
          <div>
            <ReaderLink
              appealId={appealId}
              analyticsSource="queue_task"
              redirectUrl={redirectUrl}
              appeal={appeal}
              taskType={taskType}
              docCountWithinLink
              newDocsIcon />
          </div>
        </React.Fragment> }

      <React.Fragment>
        <h4>{COPY.TASK_SNAPSHOT_ABOUT_BOX_TYPE_LABEL}</h4>
        <div>
          {renderLegacyAppealType({
            aod: appeal.isAdvancedOnDocket,
            type: appeal.caseType
          })}

          {!appeal.isLegacyAppeal && this.props.canEditAod && <span {...editButton}>
            <Link
              to={`/queue/appeals/${appeal.externalId}/modal/advanced_on_docket_motion`}>
              Edit
            </Link>
          </span>}
        </div>
      </React.Fragment>

      { !userIsVsoEmployee && appeal && appeal.documentID &&
        <React.Fragment>
          <h4>{COPY.TASK_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}</h4>
          <div id="document-id">
            <CopyTextButton
              text={this.state.value || appeal.documentID}
              label={COPY.TASK_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}
            />
            { appeal.canEditDocumentId &&
              <Button
                linkStyling
                onClick={this.handleModalClose} >
                <span {...css({ position: 'absolute' })}>{pencilSymbol()}</span>
                <span {...css({ marginRight: '5px',
                  marginLeft: '20px' })}>Edit</span>
              </Button>
            }
          </div>
          { this.state.showModal && <Modal
            buttons = {[
              { classNames: ['cf-modal-link', 'cf-btn-link'],
                name: 'Cancel',
                onClick: this.handleModalClose
              },
              { classNames: ['usa-button'],
                name: 'Save',
                disabled: !this.state.value,
                onClick: this.submitForm(appeal.caseReviewId, appeal.isLegacyAppeal)
              }
            ]}
            closeHandler={this.handleModalClose}
            title = {COPY.TASK_SNAPSHOT_EDIT_DOCUMENT_ID_MODAL_TITLE}>
            <TextField
              errorMessage={highlightModal ? documentIdError : null}
              name={COPY.TASK_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}
              placeholder={appeal.documentID}
              value={this.state.value}
              onChange={this.changeButtonState}
              autoComplete="off"
              required />

          </Modal>}
        </React.Fragment> }

      { !userIsVsoEmployee && appeal.assignedJudge && !appeal.removed && appeal.status !== 'cancelled' &&
        <React.Fragment>
          <h4>{COPY.TASK_SNAPSHOT_ASSIGNED_JUDGE_LABEL}</h4>
          <div>{appeal.assignedJudge.full_name}</div>
        </React.Fragment> }

      { !userIsVsoEmployee && appeal.assignedAttorney && !appeal.removed && appeal.status !== 'cancelled' &&
        <React.Fragment>
          <h4>{COPY.TASK_SNAPSHOT_ASSIGNED_ATTORNEY_LABEL}</h4>
          <div>{appeal.assignedAttorney.full_name}</div>
        </React.Fragment> }
      { featureToggles.overtime_revamp && showOvertimeButton &&
        <React.Fragment>
          <h4>{COPY.TASK_SNAPSHOT_OVERTIME_LABEL}</h4>
          <Button
            linkStyling
            styling={overtimeButton}
            onClick={this.changeRoute} >
            <span>{clockIcon()}</span>
            <span {...overtimeLink}>&nbsp;{appeal.overtime ?
              COPY.TASK_SNAPSHOT_IS_OVERTIME : COPY.TASK_SNAPSHOT_IS_NOT_OVERTIME }
            </span>
          </Button>
        </React.Fragment> }
    </CaseDetailTitleScaffolding>;
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
  task: PropTypes.object
};

const mapStateToProps = (state, ownProps) => {
  const { userRole, userCssId, canEditAod, featureToggles, userIsVsoEmployee } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    task: tasksByAddedByCssIdSelector(state),
    userRole,
    userCssId,
    canEditAod,
    featureToggles,
    userIsVsoEmployee
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(CaseTitleDetails)
));
