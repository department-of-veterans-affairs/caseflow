import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import { getDecisionTypeDisplay, buildCaseReviewPayload, validateWorkProductTypeAndId } from './utils';

import { setDecisionOptions, deleteAppeal } from './QueueActions';
import { requestSave } from './uiReducer/uiActions';

import RadioField from '../components/RadioField';
import Checkbox from '../components/Checkbox';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import Alert from '../components/Alert';
import JudgeSelectComponent from './JudgeSelectComponent';
import InstructionalText from './InstructionalText';
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
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES';
import COPY from '../../COPY';
import QueueFlowPage from './components/QueueFlowPage';

class SubmitDecisionView extends React.PureComponent {
  componentDidMount = () => {
    this.extendedDecision = this.setInitialDecisionOptions(
      this.props.decision,
      this.props.appeal,
      this.props.appeal && this.props.appeal.attorneyCaseRewriteDetails
    );

    _.each(this.extendedDecision.opts, (value, key) => {
      this.props.setDecisionOptions({
        [key]: value
      });
    });
  };

  // this handles the case where there is no document_id on this.props.decision.opts
  // and it comes from this.props.appeal.attorneyCaseRewriteDetails instead
  // if you don't do this you will get validation errors and a 400 for a missing document_id
  // this is also needed to keep the onChange values in sync
  setInitialDecisionOptions = (decision, appeal, attorneyCaseRewriteDetails) => {
    const overtime = this.props.featureToggles.overtime_revamp ?
      appeal.overtime : _.get(attorneyCaseRewriteDetails, 'overtime', false);
    const decisionOptsWithAttorneyCheckoutInfo = _.merge(decision.opts, {
      document_id: _.get(this.props, 'appeal.documentID'),
      note: _.get(attorneyCaseRewriteDetails, 'note_from_attorney'),
      overtime: overtime || false,
      untimely_evidence: _.get(attorneyCaseRewriteDetails, 'untimely_evidence', false) || false,
      reviewing_judge_id: _.get(this.props, 'task.assignedBy.pgId')
    });
    const extendedDecision = { ...decision };

    extendedDecision.opts = decisionOptsWithAttorneyCheckoutInfo;

    return extendedDecision;
  };
  validateForm = () => {
    const { opts: decisionOpts } = this.props.decision;

    const requiredParams = ['document_id', 'reviewing_judge_id', 'work_product'];
    const missingParams = _.filter(requiredParams, (param) => !_.has(decisionOpts, param) || !decisionOpts[param]);

    const isValid = !missingParams.length;

    return isValid;
  };

  getPrevStepUrl = () => {
    const { checkoutFlow, appeal, taskId, appealId, prevUrl } = this.props;

    if (prevUrl) {
      return prevUrl;
    }

    const dispositions = _.map(appeal.issues, (issue) => issue.disposition);
    const prevPath = `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}`;

    if (checkoutFlow === DECISION_TYPES.DRAFT_DECISION) {
      return dispositions.includes(VACOLS_DISPOSITIONS.REMANDED) ? `${prevPath}/remands` : `${prevPath}/dispositions`;
    }

    return prevPath;
  };

  goToNextStep = async () => {
    const {
      task: { taskId },
      appeal: { issues, decisionIssues, veteranFullName, externalId: appealId, isLegacyAppeal },
      checkoutFlow,
      decision,
      judges
    } = this.props;
    const issuesToPass = isLegacyAppeal ? issues : decisionIssues;
    const payload = buildCaseReviewPayload(checkoutFlow, decision, true, issuesToPass, { isLegacyAppeal });


    const fields = {
      type: checkoutFlow === DECISION_TYPES.DRAFT_DECISION ? 'decision' : 'outside medical opinion (OMO) request',
      veteran: veteranFullName,
      judge: this.getJudgeValueForSuccessMessage(judges, decision)
    };
    const successMsg = `Thank you for drafting ${fields.veteran}'s ${fields.type}. It's
    been sent to ${fields.judge} for review.`;

    try {
      const res = await this.props.requestSave(`/case_reviews/${taskId}/complete`, payload, { title: successMsg });

      // Perform onSuccess hook, if exists
      await this.props.onSuccess?.(res);

      this.props.deleteAppeal(appealId);
    } catch (error) {
      // handle the error from the frontend
    }
  };

  getJudgeValueForSuccessMessage = (judges, decision) => {
    const judgeIsInJudgesArray = judges[decision.opts.reviewing_judge_id];

    if (judgeIsInJudgesArray) {
      return judgeIsInJudgesArray.full_name;
    }
    if (this.props.task && this.props.task.assignedBy) {
      return `${this.props.task.assignedBy.first_name} ${this.props.task.assignedBy.last_name}`;
    }

    return '';
  };

  getDefaultJudgeSelector = () => {
    return this.props.task && this.props.task.isLegacy ?
      this.props.task.addedByCssId :
      this.props.task && this.props.task.assignedBy.pgId;
  };

  render = () => {
    const {
      highlightFormItems,
      error,
      featureToggles,
      checkoutFlow,
      decision: { opts: decisionOpts },
      ...otherProps
    } = this.props;

    const decisionTypeDisplay = getDecisionTypeDisplay(checkoutFlow);
    let documentIdErrorMessage = '';

    if (!decisionOpts.document_id) {
      documentIdErrorMessage = 'Document id field is required';
    } else if (checkoutFlow === DECISION_TYPES.OMO_REQUEST && !validateWorkProductTypeAndId(this.props.decision)) {
      documentIdErrorMessage = COPY.FORM_ERROR_FIELD_INVALID;
    }

    return (
      <QueueFlowPage
        goToNextStep={this.goToNextStep}
        getPrevStepUrl={this.getPrevStepUrl}
        validateForm={this.validateForm}
        {...otherProps}
      >
        <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
          Submit {decisionTypeDisplay} for Review
        </h1>
        <p className="cf-lead-paragraph" {...marginBottom(2)}>
          Complete the details below to submit this {decisionTypeDisplay} request for judge review.
        </p>
        {error && (
          <Alert title={error.title} type="error" styling={css(marginTop(0), marginBottom(2))}>
            {error.detail}
          </Alert>
        )}
        <hr />
        {checkoutFlow === DECISION_TYPES.OMO_REQUEST && (
          <RadioField
            name="omo_type"
            label="OMO type:"
            onChange={(value) => this.props.setDecisionOptions({ work_product: value })}
            value={decisionOpts.work_product}
            vertical
            options={OMO_ATTORNEY_CASE_REVIEW_WORK_PRODUCT_TYPES}
            errorMessage={highlightFormItems && !decisionOpts.work_product ? 'OMO type field is required' : ''}
          />
        )}
        <TextField
          label="Document ID:"
          name="document_id"
          errorMessage={highlightFormItems ? documentIdErrorMessage : null}
          onChange={(value) => this.props.setDecisionOptions({ document_id: value })}
          value={decisionOpts.document_id}
          maxLength={DOCUMENT_ID_MAX_LENGTH}
          autoComplete="off"
        />
        <JudgeSelectComponent judgeSelector={this.getDefaultJudgeSelector()} />
        <TextareaField
          label="Notes:"
          name="notes"
          value={decisionOpts.note || ''}
          onChange={(note) => this.props.setDecisionOptions({ note })}
          styling={marginTop(4)}
          maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
        />
        {featureToggles.overtime_revamp || <Checkbox
          name="overtime"
          label="This work product is overtime"
          onChange={(overtime) => this.props.setDecisionOptions({ overtime })}
          value={decisionOpts.overtime || false}
          styling={css(marginBottom(1), marginTop(1))}
        /> }
        {!this.props.appeal.isLegacyAppeal && (
          <div>
            <Checkbox
              name="untimely_evidence"
              label="The Veteran submitted evidence that is ineligible for review"
              onChange={(untimelyEvidence) => this.props.setDecisionOptions({ untimely_evidence: untimelyEvidence })}
              value={decisionOpts.untimely_evidence || false}
              styling={css(marginBottom(1), marginTop(1))}
            />
            <InstructionalText
              informationalTitle={COPY.WHAT_IS_INELIGIBLE_EVIDENCE}
              informationHeader={COPY.UNTIMELY_EVIDENCE_TITLE}
              bulletOne={COPY.UNTIMELY_EVIDENCE_BULLET_ONE}
              bulletTwo={COPY.UNTIMELY_EVIDENCE_BULLET_TWO}
              bulletThree={COPY.UNTIMELY_EVIDENCE_BULLET_THREE}
            />
          </div>
        )}
      </QueueFlowPage>
    );
  };
}

const mapStateToProps = (state, ownProps) => {
  const {
    queue: {
      judges,
      stagedChanges: {
        appeals: { [ownProps.appealId]: appeal },
        taskDecision: decision
      }
    },
    ui: {
      featureToggles,
      highlightFormItems,
      messages: { error }
    }
  } = state;

  return {
    appeal,
    judges,
    task: taskById(state, { taskId: ownProps.taskId }),
    decision,
    error,
    featureToggles,
    highlightFormItems
  };
};

SubmitDecisionView.propTypes = {
  taskId: PropTypes.string,
  task: PropTypes.shape({
    taskId: PropTypes.string,
    assignedBy: PropTypes.object,
    isLegacy: PropTypes.bool,
    addedByCssId: PropTypes.string
  }),
  appealId: PropTypes.string,
  appeal: PropTypes.shape({
    issues: PropTypes.array,
    decisionIssues: PropTypes.array,
    veteranFullName: PropTypes.string,
    externalId: PropTypes.string,
    isLegacyAppeal: PropTypes.bool,
    attorneyCaseRewriteDetails: PropTypes.object
  }),
  checkoutFlow: PropTypes.string,
  decision: PropTypes.shape({ opts: PropTypes.object }),
  deleteAppeal: PropTypes.func,
  error: PropTypes.object,
  featureToggles: PropTypes.object,
  highlightFormItems: PropTypes.bool,
  judges: PropTypes.array,
  onSuccess: PropTypes.func,
  prevUrl: PropTypes.string,
  requestSave: PropTypes.func,
  setDecisionOptions: PropTypes.func
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      setDecisionOptions,
      requestSave,
      deleteAppeal
    },
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(SubmitDecisionView);
