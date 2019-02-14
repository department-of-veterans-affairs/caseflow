// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import {
  getDecisionTypeDisplay,
  buildCaseReviewPayload,
  validateWorkProductTypeAndId
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

import type {
  Task,
  Appeal,
  Judges
} from './types/models';
import type { UiStateMessage } from './types/state';

type Params = {|
  appealId: string,
  taskId: string,
  checkoutFlow: string,
  nextStep: string
|};

type Props = Params & {|
  // state
  appeal: Appeal,
  judges: Judges,
  decision: Object,
  task: Task,
  highlightFormItems: Boolean,
  amaDecisionIssues: Boolean,
  userRole: string,
  error: ?UiStateMessage,
  // dispatch
  setDecisionOptions: typeof setDecisionOptions,
  requestSave: typeof requestSave,
  deleteAppeal: typeof deleteAppeal
|};

class SubmitDecisionView extends React.PureComponent<Props> {
  validateForm = () => {
    const {
      opts: decisionOpts
    } = this.props.decision;
    const requiredParams = ['document_id', 'reviewing_judge_id', 'work_product'];

    const missingParams = _.filter(requiredParams, (param) => !_.has(decisionOpts, param) || !decisionOpts[param]);

    return !missingParams.length;
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
    const payload = buildCaseReviewPayload(checkoutFlow, decision, userRole, issuesToPass, { isLegacyAppeal });

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
      <Checkbox
        name="overtime"
        label="This work product is overtime"
        onChange={(overtime) => this.props.setDecisionOptions({ overtime })}
        value={decisionOpts.overtime || false}
        styling={css(marginBottom(1), marginTop(1))}
      />
      <TextField
        label="Document ID:"
        name="document_id"
        errorMessage={highlightFormItems ? documentIdErrorMessage : null}
        onChange={(value) => this.props.setDecisionOptions({ document_id: value })}
        value={decisionOpts.document_id}
        maxLength={DOCUMENT_ID_MAX_LENGTH}
        autoComplete="off"
      />
      <JudgeSelectComponent assignedByCssId={
        (this.props.task && this.props.task.addedByCssId) || '' /* not compatible with AMA tasks */
      } />
      <TextareaField
        label="Notes:"
        name="notes"
        value={decisionOpts.note}
        onChange={(note) => this.props.setDecisionOptions({ note })}
        styling={marginTop(4)}
        maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
      />
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
    amaDecisionIssues: state.ui.featureToggles.ama_decision_issues || !_.isEmpty(appeal.decisionIssues)
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
): React.ComponentType<Params>
);
