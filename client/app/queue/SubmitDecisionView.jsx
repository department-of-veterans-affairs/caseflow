import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import Button from '../components/Button';
import _ from 'lodash';
import {
  getDecisionTypeDisplay,
  buildCaseReviewPayload,
  validateWorkProductTypeAndId,
  nullToFalse
} from './utils';

import {
  setDecisionOptions,
  deleteAppeal
} from './QueueActions';
import { requestSave } from './uiReducer/uiActions';

import decisionViewBase from './components/DecisionViewBase';
import RadioField from '../components/RadioField';
import Checkbox from '../components/Checkbox';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import Alert from '../components/Alert';
import JudgeSelectComponent from './JudgeSelectComponent';
import { taskById } from './selectors';

import {
  fullWidth,
  marginBottom,
  marginTop,
  ATTORNEY_COMMENTS_MAX_LENGTH,
  DOCUMENT_ID_MAX_LENGTH,
  OMO_ATTORNEY_CASE_REVIEW_WORK_PRODUCT_TYPES,
  VACOLS_DISPOSITIONS
} from './constants';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';
import COPY from '../../COPY.json';
const verticalLine = css(
  {
    borderLeft: 'thick solid lightgrey',
    marginLeft: '20px',
    paddingLeft: '20px'
  }
);

class SubmitDecisionView extends React.PureComponent {
  linkClicked = false;
  componentDidMount = () => {
    this.extendedDecision = this.setInitialDecisionOptions(
      this.props.decision,
      this.props.appeal && this.props.appeal.attorneyCaseRewriteDetails);

    _.each(this.extendedDecision.opts, (value, key) => {
      this.props.setDecisionOptions({
        [key]: value
      });
    });
  }

  // this handles the case where there is no document_id on this.props.decision.opts
  // and it comes from this.props.appeal.attorneyCaseRewriteDetails instead
  // if you don't do this you will get validation errors and a 400 for a missing document_id
  // this is also needed to keep the onChange values in sync
  setInitialDecisionOptions = (decision, attorneyCaseRewriteDetails) => {
    const decisionOptsWithAttorneyCheckoutInfo =
    _.merge(decision.opts, { document_id: _.get(this.props, 'appeal.documentID'),
      note: _.get(attorneyCaseRewriteDetails, 'note_from_attorney'),
      overtime: _.get(attorneyCaseRewriteDetails, 'overtime', false),
      untimely_evidence: _.get(attorneyCaseRewriteDetails, 'untimely_evidence', false),
      reviewing_judge_id: _.get(this.props, 'task.assignedBy.pgId')
    });
    const extendedDecision = { ...decision };

    extendedDecision.opts = decisionOptsWithAttorneyCheckoutInfo;

    if (extendedDecision.opts) {
      const possibleNullKeys = ['overtime', 'untimely_evidence'];

      possibleNullKeys.forEach((key) => {
        extendedDecision.opts = nullToFalse(key, extendedDecision.opts);
      });
    }

    return extendedDecision;
  }
  validateForm = () => {
    const {
      opts: decisionOpts
    } = this.props.decision;

    const requiredParams = ['document_id', 'reviewing_judge_id', 'work_product'];
    const missingParams = _.filter(requiredParams, (param) => !_.has(decisionOpts, param) || !decisionOpts[param]);

    const isValid = !missingParams.length;

    return isValid;
  };

  getPrevStepUrl = () => {
    const {
      checkoutFlow,
      appeal,
      taskId,
      appealId
    } = this.props;
    const dispositions = _.map(appeal.issues, (issue) => issue.disposition);
    const prevUrl = `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}`;

    if (checkoutFlow === DECISION_TYPES.DRAFT_DECISION) {
      return dispositions.includes(VACOLS_DISPOSITIONS.REMANDED) ?
        `${prevUrl}/remands` :
        `${prevUrl}/dispositions`;
    }

    return prevUrl;
  }

  goToNextStep = () => {
    const {
      task: { taskId },
      appeal: {
        issues,
        decisionIssues,
        veteranFullName,
        externalId: appealId,
        isLegacyAppeal
      },
      checkoutFlow,
      decision,
      userRole,
      judges,
      amaDecisionIssues
    } = this.props;

    const issuesToPass = !isLegacyAppeal && amaDecisionIssues ? decisionIssues : issues;
    const payload = buildCaseReviewPayload(checkoutFlow, decision,
      userRole, issuesToPass, { isLegacyAppeal });

    const fields = {
      type: checkoutFlow === DECISION_TYPES.DRAFT_DECISION ?
        'decision' : 'outside medical opinion (OMO) request',
      veteran: veteranFullName,
      judge: judges[decision.opts.reviewing_judge_id].full_name
    };
    const successMsg = `Thank you for drafting ${fields.veteran}'s ${fields.type}. It's
    been sent to ${fields.judge} for review.`;

    this.props.requestSave(`/case_reviews/${taskId}/complete`, payload, { title: successMsg }).
      then(() => {
        this.props.deleteAppeal(appealId);
      }).
      catch(() => {
        // handle the error from the frontend
      });
  };

  getDefaultJudgeSelector = () => {
    return this.props.task && this.props.task.isLegacy ?
      this.props.task.addedByCssId :
      this.props.task && this.props.task.assignedBy.pgId;
  }

  render = () => {
    const {
      highlightFormItems,
      error,
      checkoutFlow,
      decision: {
        opts: decisionOpts
      }
    } = this.props;

    const decisionTypeDisplay = getDecisionTypeDisplay(checkoutFlow);
    let documentIdErrorMessage = '';

    if (!decisionOpts.document_id) {
      documentIdErrorMessage = COPY.FORM_ERROR_FIELD_REQUIRED;
    } else if (checkoutFlow === DECISION_TYPES.OMO_REQUEST && !validateWorkProductTypeAndId(this.props.decision)) {
      documentIdErrorMessage = COPY.FORM_ERROR_FIELD_INVALID;
    }

    return <React.Fragment>
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        Submit {decisionTypeDisplay} for Review
      </h1>
      <p className="cf-lead-paragraph" {...marginBottom(2)}>
        Complete the details below to submit this {decisionTypeDisplay} request for judge review.
      </p>
      {error && <Alert title={error.title} type="error" styling={css(marginTop(0), marginBottom(2))}>
        {error.detail}
      </Alert>}
      <hr />
      {checkoutFlow === DECISION_TYPES.OMO_REQUEST && <RadioField
        name="omo_type"
        label="OMO type:"
        onChange={(value) => this.props.setDecisionOptions({ work_product: value })}
        value={decisionOpts.work_product}
        vertical
        options={OMO_ATTORNEY_CASE_REVIEW_WORK_PRODUCT_TYPES}
        errorMessage={(highlightFormItems && !decisionOpts.work_product) ? COPY.FORM_ERROR_FIELD_REQUIRED : ''}
      />}
      <TextField
        label="Document ID:"
        name="document_id"
        errorMessage={highlightFormItems ? documentIdErrorMessage : null}
        onChange={(value) => this.props.setDecisionOptions({ document_id: value })}
        value={decisionOpts.document_id}
        maxLength={DOCUMENT_ID_MAX_LENGTH}
        autoComplete="off"
      />
      <JudgeSelectComponent
        judgeSelector={
          this.getDefaultJudgeSelector()
        }
      />
      <TextareaField
        label="Notes:"
        name="notes"
        value={decisionOpts.note || ''}
        onChange={(note) => this.props.setDecisionOptions({ note })}
        styling={marginTop(4)}
        maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
      />
      <Checkbox
        name="overtime"
        label="This work product is overtime"
        onChange={(overtime) => this.props.setDecisionOptions({ overtime })}
        value={decisionOpts.overtime || false}
        styling={css(marginBottom(1), marginTop(1))}
      />
      <Checkbox
        name="untimely_evidence"
        label="The Veteran submitted evidence that is ineligible for review"
        onChange={(untimelyEvidence) => this.props.setDecisionOptions({ untimely_evidence: untimelyEvidence })}
        value={decisionOpts.untimely_evidence || false}
        styling={css(marginBottom(1), marginTop(1))}
      />
      {/* TODO: 1. componentize this once the style guide directives are in 
                2. add in arrow to the left of link once provided by UX team */}
      <Button
        id="ineligible-evidence"
        linkStyling
        willNeverBeLoading
        onClick={() => {
          this.linkClicked = !this.linkClicked;
          this.setState({ linkClicked: this.linkClicked,
            buttonDirection: this.linkClicked ? 'down' : 'right' });
        }}>
        {COPY.WHAT_IS_INELIGIBLE_EVIDENCE}
      </Button>
      {this.linkClicked && <div {...verticalLine}>
        <div>{COPY.UNTIMELY_EVIDENCE_TITLE}</div>
        <br />
        <div>{COPY.UNTIMELY_EVIDENCE_BULLET_ONE}</div>
        <div> {COPY.UNTIMELY_EVIDENCE_BULLET_TWO}</div>
        <div> {COPY.UNTIMELY_EVIDENCE_BULLET_THREE}</div>
      </div>}
    </React.Fragment>;
  };
}

const mapStateToProps = (state, ownProps) => {
  const {
    queue: {
      judges,
      stagedChanges: {
        appeals: {
          [ownProps.appealId]: appeal
        },
        taskDecision: decision
      }
    },
    ui: {
      highlightFormItems,
      userRole,
      messages: {
        error
      }
    }
  } = state;

  return {
    appeal,
    judges,
    task: taskById(state, { taskId: ownProps.taskId }),
    decision,
    error,
    userRole,
    highlightFormItems,
    amaDecisionIssues: state.ui.featureToggles.ama_decision_issues || !_.isEmpty(appeal && appeal.decisionIssues)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDecisionOptions,
  requestSave,
  deleteAppeal
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(
  decisionViewBase(SubmitDecisionView)
)
);
