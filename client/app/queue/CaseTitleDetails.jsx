import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import Modal from '../components/Modal';
import TextField from '../components/TextField';
import Button from '../components/Button';
import { bindActionCreators } from 'redux';

import {
  appealWithDetailSelector
} from './selectors';
import DocketTypeBadge from './../components/DocketTypeBadge';
import CopyTextButton from '../components/CopyTextButton';
import ReaderLink from './ReaderLink';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { pencilSymbol } from '../components/RenderFunctions';

import COPY from '../../COPY.json';
import { COLORS } from '../constants/AppConstants';
import { renderLegacyAppealType } from './utils';

import {
  requestPatch
} from './uiReducer/uiActions';

const editButton = css({
  float: 'right',
  marginLeft: '0.5rem'
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

  render = () => {
    const {
      appeal,
      appealId,
      redirectUrl,
      taskType,
      userIsVsoEmployee
    } = this.props;

    const {
      highlightModal,
      documentIdError
    } = this.state;

    return <CaseDetailTitleScaffolding>
      <React.Fragment>
        <h4>{COPY.TASK_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL}</h4>
        <div>
          <span {...docketBadgeContainerStyle}>
            <DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />{appeal.docketNumber}
          </span>
        </div>
      </React.Fragment>

      { !userIsVsoEmployee &&
        <React.Fragment>
          <h4>Veteran Documents</h4>
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
          <div id="document-id"><CopyTextButton text={this.state.value || appeal.documentID} />
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

      { !userIsVsoEmployee && appeal.assignedJudge && <React.Fragment>
        <h4>{COPY.TASK_SNAPSHOT_ASSIGNED_JUDGE_LABEL}</h4>
        <div>{appeal.assignedJudge.full_name}</div>
      </React.Fragment> }

      { !userIsVsoEmployee && appeal.assignedAttorney && <React.Fragment>
        <h4>{COPY.TASK_SNAPSHOT_ASSIGNED_ATTORNEY_LABEL}</h4>
        <div>{appeal.assignedAttorney.full_name}</div>
      </React.Fragment> }
    </CaseDetailTitleScaffolding>;
  };
}

const mapStateToProps = (state, ownProps) => {
  const { featureToggles, userRole, canEditAod } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    featureToggles,
    userRole,
    canEditAod,
    userIsVsoEmployee: state.ui.userIsVsoEmployee
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(CaseTitleDetails));
