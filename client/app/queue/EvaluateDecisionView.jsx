/* eslint-disable no-console */
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import moment from 'moment';
import scrollToComponent from 'react-scroll-to-component';
import { sprintf } from 'sprintf-js';

import decisionViewBase from './components/DecisionViewBase';
import RadioField from '../components/RadioField';
import CheckboxGroup from '../components/CheckboxGroup';
import Checkbox from '../components/Checkbox';
import TextareaField from '../components/TextareaField';
import CaseTitle from './CaseTitle';
import Alert from '../components/Alert';
import TaskSnapshot from './TaskSnapshot';

import { deleteAppeal } from './QueueActions';
import { requestSave } from './uiReducer/uiActions';
import { buildCaseReviewPayload } from './utils';
import { taskById } from './selectors';

import COPY from '../../COPY.json';
import JUDGE_CASE_REVIEW_OPTIONS from '../../constants/JUDGE_CASE_REVIEW_OPTIONS.json';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';
import {
  marginBottom, marginTop,
  paddingLeft, fullWidth,
  redText, PAGE_TITLES,
  VACOLS_DISPOSITIONS,
  ISSUE_DISPOSITIONS,
  JUDGE_CASE_REVIEW_COMMENT_MAX_LENGTH
} from './constants';
import DispatchSuccessDetail from './components/DispatchSuccessDetail';

const setWidth = (width) => css({
  width,
  maxWidth: width
});
const headerStyling = marginBottom(1.5);
const inlineHeaderStyling = css(headerStyling, { float: 'left' });
const hrStyling = css(marginTop(2), marginBottom(3));
const qualityOfWorkAlertStyling = css({ borderLeft: '0.5rem solid #59BDE1' });
const errorStylingNoTopMargin = css({ '&.usa-input-error': marginTop(0) });
const subH2Styling = css(paddingLeft(1), { lineHeight: 2 });
const subH3Styling = css(paddingLeft(1), { lineHeight: 1.75 });
const fullWidthCheckboxLabels = css(setWidth('100%'));

class EvaluateDecisionView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      one_touch_initiative: false,
      complexity: null,
      quality: null,
      factors_not_considered: {},
      areas_for_improvement: {},
      comment: ''
    };
  }

  componentDidMount = () => this.setState(
    _.pick(this.props.taskOptions, _.keys(this.state))
  );

  getPageName = () => PAGE_TITLES.EVALUATE;

  qualityIsDeficient = () => ['needs_improvements', 'does_not_meet_expectations'].includes(this.state.quality);

  // todo: consoldate w/IssueRemandReasonOptions.scrollTo
  // moving these into DecisionViewBase didn't work for some reason :\
  scrollTo = (dest = this, opts) => scrollToComponent(dest, _.defaults(opts, {
    align: 'top',
    duration: 1500,
    ease: 'outCube',
    offset: -10
  }));

  validateForm = () => {
    const {
      areas_for_improvement,
      factors_not_considered,
      complexity,
      quality
    } = this.state;

    if (!complexity) {
      this.scrollTo(this.complexityLabel);

      return false;
    }

    if (!quality) {
      this.scrollTo(this.qualityLabel);

      return false;
    }

    // eslint-disable-next-line camelcase
    if (this.qualityIsDeficient() && _.every([areas_for_improvement, factors_not_considered], _.isEmpty)) {
      this.scrollTo(this.deficientQualityAlert);

      return false;
    }

    return true;
  };

  getPrevStepUrl = () => {
    const {
      appealId,
      taskId,
      checkoutFlow,
      appeal
    } = this.props;
    const prevUrl = `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}`;
    const dispositions = _.map(appeal.issues, (issue) => issue.disposition);
    const remandedIssues = _.some(dispositions, (disposition) => [
      VACOLS_DISPOSITIONS.REMANDED, ISSUE_DISPOSITIONS.REMANDED
    ].includes(disposition));

    return `${prevUrl}/${remandedIssues ? 'remands' : 'dispositions'}`;
  }

  goToNextStep = () => {
    const {
      task,
      appeal,
      checkoutFlow,
      decision,
      userRole,
      appealId,
      amaDecisionIssues
    } = this.props;

    let loc = 'bva_dispatch';
    let successMsg = sprintf(COPY.JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE, appeal.veteranFullName);

    if (checkoutFlow === DECISION_TYPES.OMO_REQUEST) {
      loc = 'omo_office';
      successMsg = sprintf(COPY.JUDGE_CHECKOUT_OMO_SUCCESS_MESSAGE_TITLE, appeal.veteranFullName);
    }
    const issuesToPass = !appeal.isLegacyAppeal && amaDecisionIssues ? appeal.decisionIssues : appeal.issues;
    const payload = buildCaseReviewPayload(checkoutFlow, decision, userRole, issuesToPass, {
      location: loc,
      attorney_id: appeal.isLegacyAppeal ? task.assignedBy.pgId : appeal.assignedAttorney.id,
      isLegacyAppeal: appeal.isLegacyAppeal,
      ...this.state
    });

    this.props.requestSave(
      `/case_reviews/${task.taskId}/complete`,
      payload,
      { title: successMsg,
        detail: <DispatchSuccessDetail task={task} /> }).
      then(() => this.props.deleteAppeal(appealId), (response) => {
        // eslint-disable-next-line no-console
        console.log(response);
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  getDisplayOptions = (opts) => _.map(JUDGE_CASE_REVIEW_OPTIONS[opts.toUpperCase()],
    (value, key) => ({
      id: key,
      label: value
    }));

  setStateAttrList = (event, key = 'factors_not_considered') => {
    const factor = event.target.name;
    const newOpts = this.state[key];

    if (factor in this.state[key]) {
      delete newOpts[factor];
    } else {
      newOpts[factor] = true;
    }

    this.setState({ [key]: newOpts });
  }

  setAreasOfImprovement = (event) => this.setStateAttrList(event, 'areas_for_improvement');

  render = () => {
    const {
      appeal,
      task,
      appealId,
      highlight,
      error
    } = this.props;

    const dateAssigned = moment(task.previousTaskAssignedOn);
    const decisionSubmitted = moment(task.assignedOn);
    const daysWorked = decisionSubmitted.startOf('day').
      diff(dateAssigned, 'days');

    return <React.Fragment>
      <CaseTitle
        heading={appeal.veteranFullName}
        appealId={appealId}
        appeal={this.props.appeal}
        analyticsSource="evaluate_decision"
        taskType="Dispatch"
        redirectUrl={window.location.pathname} />
      <h1 {...css(fullWidth, marginBottom(2), marginTop(2))}>
        {this.getPageName()}
      </h1>
      {error && <Alert title={error.title} type="error" styling={css(marginTop(0), marginBottom(1))}>
        {error.detail}
      </Alert>}
      <TaskSnapshot appealId={appealId} hideDropdown />
      <hr {...hrStyling} />

      {appeal.isLegacyAppeal && <React.Fragment>
        <h2 {...headerStyling}>{COPY.JUDGE_EVALUATE_DECISION_CASE_ONE_TOUCH_INITIATIVE_LABEL}</h2>
        <Checkbox
          label={<b>{COPY.JUDGE_EVALUATE_DECISION_CASE_ONE_TOUCH_INITIATIVE_SUBHEAD}</b>}
          name="One Touch Initiative"
          value={this.state.one_touch_initiative}
          onChange={(value) => {
            this.setState({ one_touch_initiative: value });
          }}
        />
        <hr {...hrStyling} /></React.Fragment>}

      <h2 {...headerStyling}>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_LABEL}</h2>
      <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_ASSIGNED_DATE}</b>: {dateAssigned.format('M/D/YY')}<br />
      <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_SUBMITTED_DATE}</b>: {decisionSubmitted.format('M/D/YY')}<br />
      <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED}</b>&nbsp;
      ({COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED_ADDENDUM}): {daysWorked}<br />

      <hr {...hrStyling} />

      <h2 {...headerStyling} ref={(node) => this.complexityLabel = node}>
        {COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_LABEL}
      </h2>
      <h3>{COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_SUBHEAD}</h3>
      <RadioField vertical hideLabel
        name={COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_LABEL}
        onChange={(complexity) => this.setState({ complexity })}
        value={this.state.complexity}
        styling={css(marginBottom(0), errorStylingNoTopMargin)}
        errorMessage={highlight && !this.state.complexity ? 'Choose one' : null}
        options={_.map(JUDGE_CASE_REVIEW_OPTIONS.COMPLEXITY, (value, key) => ({
          value: key,
          displayText: value
        }))} />

      <hr {...hrStyling} />

      <h2 {...headerStyling} ref={(node) => this.qualityLabel = node}>
        {COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_LABEL}
      </h2>
      <h3>{COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_SUBHEAD}</h3>
      <RadioField vertical hideLabel
        name={COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_LABEL}
        onChange={(quality) => this.setState({ quality })}
        value={this.state.quality}
        styling={css(marginBottom(0), errorStylingNoTopMargin)}
        errorMessage={highlight && !this.state.quality ? 'Choose one' : null}
        options={_.map(JUDGE_CASE_REVIEW_OPTIONS.QUALITY, (val, key, obj) => ({
          value: key,
          displayText: `${_.size(obj) - Object.keys(obj).indexOf(key)} - ${val}`
        }))} />

      {this.qualityIsDeficient() && <Alert ref={(node) => this.deficientQualityAlert = node}
        type="info"
        scrollOnAlert={false}
        styling={qualityOfWorkAlertStyling}>
        Please provide more details about <b>quality of work</b>. If none of these apply to
        this case, please share <b>additional comments</b> below.
      </Alert>}

      <div {...css(setWidth('100%'), marginTop(4))}>
        <h3 {...css(headerStyling, { float: this.qualityIsDeficient() ? 'left' : '' })}>
          {COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
        </h3>
        {this.qualityIsDeficient() && <span {...css(subH3Styling, redText)}>Choose at least one</span>}
      </div>
      <div className="cf-push-left" {...fullWidth}>
        <h4>{COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_NOT_CONSIDERED}</h4>
        <CheckboxGroup
          hideLabel vertical
          name={COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
          onChange={this.setStateAttrList}
          value={this.state.factors_not_considered}
          options={this.getDisplayOptions('factors_not_considered')}
          styling={fullWidthCheckboxLabels} />
      </div>
      <div className="cf-push-left" {...fullWidth}>
        <h4>{COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_AREAS_FOR_IMPROVEMENT}</h4>
        <CheckboxGroup
          hideLabel vertical
          name={COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
          onChange={this.setAreasOfImprovement}
          errorState={highlight && this.qualityIsDeficient() && _.isEmpty(this.state.areas_for_improvement)}
          value={this.state.areas_for_improvement}
          options={this.getDisplayOptions('areas_for_improvement')}
          styling={fullWidthCheckboxLabels} />
      </div>

      <hr {...hrStyling} />

      <h2 {...inlineHeaderStyling}>{COPY.JUDGE_EVALUATE_DECISION_ADDITIONAL_FACTORS_LABEL}</h2>
      <span {...subH2Styling}>Optional</span>
      <h3>{COPY.JUDGE_EVALUATE_DECISION_ADDITIONAL_FACTORS_SUBHEAD}</h3>
      <TextareaField
        name="additional-factors"
        label={COPY.JUDGE_EVALUATE_DECISION_ADDITIONAL_FACTORS_SUBHEAD}
        hideLabel
        maxlength={JUDGE_CASE_REVIEW_COMMENT_MAX_LENGTH}
        value={this.state.comment}
        onChange={(comment) => this.setState({ comment })} />
    </React.Fragment>;
  };
}

EvaluateDecisionView.propTypes = {
  checkoutFlow: PropTypes.string.isRequired,
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => {
  const appeal = state.queue.stagedChanges.appeals[ownProps.appealId];

  return {
    appeal,
    highlight: state.ui.highlightFormItems,
    taskOptions: state.queue.stagedChanges.taskDecision.opts,
    task: taskById(state, { taskId: ownProps.taskId }),
    decision: state.queue.stagedChanges.taskDecision,
    userRole: state.ui.userRole,
    error: state.ui.messages.error,
    amaDecisionIssues: state.ui.featureToggles.ama_decision_issues || !_.isEmpty(appeal.decisionIssues)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  deleteAppeal,
  requestSave
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(EvaluateDecisionView));
