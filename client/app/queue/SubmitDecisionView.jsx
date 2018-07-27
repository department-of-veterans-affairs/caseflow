// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import classNames from 'classnames';
import {
  getDecisionTypeDisplay,
  buildCaseReviewPayload,
  validateWorkProductTypeAndId
} from './utils';

import {
  setDecisionOptions,
  resetDecisionOptions,
  deleteAppeal
} from './QueueActions';
import { requestSave } from './uiReducer/uiActions';

import decisionViewBase from './components/DecisionViewBase';
import RadioField from '../components/RadioField';
import Checkbox from '../components/Checkbox';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import Button from '../components/Button';
import Alert from '../components/Alert';
import JudgeSelectComponent from './JudgeSelectComponent';

import {
  fullWidth,
  marginBottom,
  marginTop,
  ATTORNEY_COMMENTS_MAX_LENGTH,
  DOCUMENT_ID_MAX_LENGTH,
  OMO_ATTORNEY_CASE_REVIEW_WORK_PRODUCT_TYPES,
  ISSUE_DISPOSITIONS
} from './constants';
import SearchableDropdown from '../components/SearchableDropdown';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';
import COPY from '../../COPY.json';

const radioFieldStyling = css(marginBottom(0), marginTop(2), {
  '& .question-label': marginBottom(0)
});
const selectJudgeButtonStyling = (selectedJudge) => css({ paddingLeft: selectedJudge ? '' : 0 });

import type {
  Task,
  LegacyAppeal,
  Judges
} from './types/models';
import type { UiStateError } from './types/state';

type Params = {|
  appealId: string,
  nextStep: string
|};

type Props = Params & {|
  // state
  appeal: LegacyAppeal,
  decision: Object,
  task: Task,
  highlightFormItems: Boolean,
  userRole: string,
  error: ?UiStateError,
  // dispatch
  setDecisionOptions: typeof setDecisionOptions,
  resetDecisionOptions: typeof resetDecisionOptions,
  requestSave: typeof requestSave,
  deleteAppeal: typeof deleteAppeal
|};

class SubmitDecisionView extends React.PureComponent<Props> {
  validateForm = () => {
    const {
      type: decisionType,
      opts: decisionOpts
    } = this.props.decision;
    const requiredParams = ['document_id', 'reviewing_judge_id'];

    if (decisionType === DECISION_TYPES.OMO_REQUEST) {
      requiredParams.push('work_product');

      if (!validateWorkProductTypeAndId(this.props.decision)) {
        return false;
      }
    }

    const missingParams = _.filter(requiredParams, (param) => !_.has(decisionOpts, param) || !decisionOpts[param]);

    return !missingParams.length;
  };

  getPrevStepUrl = () => {
    const {
      decision: { type: decisionType },
      appeal: { attributes: appeal },
      appealId
    } = this.props;
    const dispositions = _.map(appeal.issues, (issue) => issue.disposition);
    const prevUrl = `/queue/appeals/${appealId}`;

    if (decisionType === DECISION_TYPES.DRAFT_DECISION) {
      return dispositions.includes(ISSUE_DISPOSITIONS.REMANDED) ?
        `${prevUrl}/remands` :
        `${prevUrl}/dispositions`;
    }

    return prevUrl;
  }

  goToNextStep = () => {
    const {
      task: { attributes: { task_id: taskId } },
      appeal: {
        attributes: {
          issues,
          veteran_full_name,
          vacols_id: appealId
        }
      },
      decision,
      userRole,
      judges
    } = this.props;

    const payload = buildCaseReviewPayload(decision, userRole, issues);

    const fields = {
      type: decision.type === DECISION_TYPES.DRAFT_DECISION ?
        'decision' : 'outside medical opinion (OMO) request',
      veteran: veteran_full_name,
      judge: judges[decision.opts.reviewing_judge_id].full_name
    };
    const successMsg = `Thank you for drafting ${fields.veteran}'s ${fields.type}. It's
    been sent to ${fields.judge} for review.`;

    this.props.requestSave(`/case_reviews/${taskId}/complete`, payload, successMsg).
      then(() => this.props.deleteAppeal(appealId));
  };

  render = () => {
    const {
      highlightFormItems,
      error,
      decision,
      decision: {
        type: decisionType,
        opts: decisionOpts
      }
    } = this.props;
    const decisionTypeDisplay = getDecisionTypeDisplay(decision);
    let documentIdErrorMessage = '';

    if (!decisionOpts.document_id) {
      documentIdErrorMessage = COPY.FORM_ERROR_FIELD_REQUIRED;
    } else if (!validateWorkProductTypeAndId(this.props.decision)) {
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
      {decisionType === DECISION_TYPES.OMO_REQUEST && <RadioField
        name="omo_type"
        label="OMO type:"
        onChange={(value) => this.props.setDecisionOptions({ work_product: value })}
        value={decisionOpts.work_product}
        vertical
        options={OMO_ATTORNEY_CASE_REVIEW_WORK_PRODUCT_TYPES}
        styling={radioFieldStyling}
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
      />
      <JudgeSelectComponent assignedByCssId={this.props.task.added_by_css_id}/>
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
      stagedChanges: {
        appeals: {
          [ownProps.appealId]: appeal
        },
        taskDecision: decision
      },
      tasks: {
        [ownProps.appealId]: task
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
    task,
    decision,
    error,
    userRole,
    highlightFormItems,
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDecisionOptions,
  resetDecisionOptions,
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
