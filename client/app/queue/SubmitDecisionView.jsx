import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import classNames from 'classnames';
import {
  getDecisionTypeDisplay,
  buildCaseReviewPayload
} from './utils';

import {
  setDecisionOptions,
  resetDecisionOptions,
  deleteAppeal
} from './QueueActions';
import {
  setSelectingJudge,
  requestSave
} from './uiReducer/uiActions';

import decisionViewBase from './components/DecisionViewBase';
import RadioField from '../components/RadioField';
import Checkbox from '../components/Checkbox';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import Button from '../components/Button';
import Alert from '../components/Alert';

import {
  fullWidth,
  marginBottom,
  marginTop,
  ERROR_FIELD_REQUIRED,
  ATTORNEY_COMMENTS_MAX_LENGTH
} from './constants';
import SearchableDropdown from '../components/SearchableDropdown';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';

const radioFieldStyling = css(marginBottom(0), marginTop(2), {
  '& .question-label': marginBottom(0)
});
const selectJudgeButtonStyling = (selectedJudge) => css({ paddingLeft: selectedJudge ? '' : 0 });

class SubmitDecisionView extends React.PureComponent {
  componentDidMount = () => {
    const { task: { attributes: task } } = this.props;
    const judge = this.props.judges[task.added_by_css_id];

    if (judge) {
      this.props.setDecisionOptions({
        judge: {
          label: task.added_by_name,
          value: judge.id
        }
      });
    }
  };

  getBreadcrumb = () => ({
    breadcrumb: `Submit ${getDecisionTypeDisplay(this.props.decision)}`,
    path: `/queue/appeals/${this.props.appealId}/submit`
  });

  validateForm = () => {
    const {
      type: decisionType,
      opts: decisionOpts
    } = this.props.decision;
    const requiredParams = ['document_id', 'reviewing_judge_id'];

    if (decisionType === DECISION_TYPES.OMO_REQUEST) {
      requiredParams.push('work_product');
    }

    const missingParams = _.filter(requiredParams, (param) => !_.has(decisionOpts, param) || !decisionOpts[param]);

    return !missingParams.length;
  };

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

  getJudgeSelectComponent = () => {
    const {
      selectingJudge,
      judges,
      decision: { opts: decisionOpts },
      highlightFormItems
    } = this.props;
    let componentContent = <span />;
    const selectedJudge = _.get(this.props.judges, decisionOpts.reviewing_judge_id);
    const shouldDisplayError = highlightFormItems && !selectedJudge;
    const fieldClasses = classNames({
      'usa-input-error': shouldDisplayError
    });

    if (selectingJudge) {
      componentContent = <React.Fragment>
        <SearchableDropdown
          name="Select a judge"
          placeholder="Select a judge&hellip;"
          options={_.map(judges, (judge, value) => ({
            label: judge.full_name,
            value
          }))}
          onChange={({ value }) => {
            this.props.setSelectingJudge(false);
            this.props.setDecisionOptions({ reviewing_judge_id: value });
          }}
          hideLabel />
      </React.Fragment>;
    } else {
      componentContent = <React.Fragment>
        {selectedJudge && <span>{selectedJudge.full_name}</span>}
        <Button
          id="select-judge"
          linkStyling
          willNeverBeLoading
          styling={selectJudgeButtonStyling(selectedJudge)}
          onClick={() => this.props.setSelectingJudge(true)}>
          Select {selectedJudge ? 'another' : 'a'} judge
        </Button>
      </React.Fragment>;
    }

    return <div className={fieldClasses}>
      <label>Submit to judge:</label>
      {shouldDisplayError && <span className="usa-input-error-message">
        {ERROR_FIELD_REQUIRED}
      </span>}
      {componentContent}
    </div>;
  };

  render = () => {
    // todo: move to constants?
    const omoTypes = [{
      displayText: 'OMO - VHA',
      value: 'OMO - VHA'
    }, {
      displayText: 'OMO - IME',
      value: 'OMO - IME'
    }];
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
        options={omoTypes}
        styling={radioFieldStyling}
        errorMessage={(highlightFormItems && !decisionOpts.work_product) ? ERROR_FIELD_REQUIRED : ''}
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
        errorMessage={(highlightFormItems && !decisionOpts.document_id) ? ERROR_FIELD_REQUIRED : ''}
        onChange={(value) => this.props.setDecisionOptions({ document_id: value })}
        value={decisionOpts.document_id}
      />
      {this.getJudgeSelectComponent()}
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

SubmitDecisionView.propTypes = {
  appealId: PropTypes.string.isRequired,
  nextStep: PropTypes.string.isRequired
};

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
      },
      judges
    },
    ui: {
      highlightFormItems,
      userRole,
      selectingJudge,
      messages: {
        error
      }
    }
  } = state;

  return {
    appeal,
    task,
    decision,
    judges,
    error,
    userRole,
    highlightFormItems,
    selectingJudge
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDecisionOptions,
  resetDecisionOptions,
  setSelectingJudge,
  requestSave,
  deleteAppeal
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SubmitDecisionView));
