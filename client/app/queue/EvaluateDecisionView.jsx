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
import TextareaField from '../components/TextareaField';
import CaseTitle from './CaseTitle';
import CaseSnapshot from './CaseSnapshot';
import Alert from '../components/Alert';

import { deleteAppeal } from './QueueActions';
import { requestSave } from './uiReducer/uiActions';
import { buildCaseReviewPayload } from './utils';
import { appealWithDetailSelector, tasksForAppealAssignedToUserSelector } from './selectors';

import COPY from '../../COPY.json';
import JUDGE_CASE_REVIEW_OPTIONS from '../../constants/JUDGE_CASE_REVIEW_OPTIONS.json';
import {
  marginBottom, marginTop,
  marginRight, paddingLeft,
  fullWidth, redText, PAGE_TITLES,
  ISSUE_DISPOSITIONS
} from './constants';
const setWidth = (width) => css({ width });
const headerStyling = marginBottom(1.5);
const inlineHeaderStyling = css(headerStyling, { float: 'left' });
const hrStyling = css(marginTop(2), marginBottom(3));
const qualityOfWorkAlertStyling = css({ borderLeft: '0.5rem solid #59BDE1' });
const errorStylingNoTopMargin = css({ '&.usa-input-error': marginTop(0) });

const twoColumnContainerStyling = css({
  display: 'inline-flex',
  width: '100%'
});
const leftColumnStyling = css({
  '@media(min-width: 950px)': setWidth('calc(50% - 2rem)'),
  '@media(max-width: 949px)': setWidth('calc(100% - 2rem)')
});
const subH2Styling = css(paddingLeft(1), { lineHeight: 2 });
const subH3Styling = css(paddingLeft(1), { lineHeight: 1.75 });

class EvaluateDecisionView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
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
      appeal
    } = this.props;
    const dispositions = _.map(appeal.issues, (issue) => issue.disposition);
    const prevUrl = `/queue/appeals/${appealId}`;

    return dispositions.includes(ISSUE_DISPOSITIONS.REMANDED) ?
      `${prevUrl}/remands` :
      `${prevUrl}/dispositions`;
  }

  goToNextStep = () => {
    const {
      task,
      appeal,
      decision,
      userRole,
      appealId
    } = this.props;
    const payload = buildCaseReviewPayload(decision, userRole, appeal.issues, {
      location: 'bva_dispatch',
      ...this.state
    });
    const successMsg = sprintf(COPY.JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE, appeal.veteranFullName);

    this.props.requestSave(`/case_reviews/${task.taskId}/complete`, payload, { title: successMsg }).
      then(() => this.props.deleteAppeal(appealId));
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
    const dateAssigned = moment(task.assignedOn);
    const decisionSubmitted = moment(task.previousTaskAssignedOn);
    const daysWorked = moment().startOf('day').
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
      <CaseSnapshot appealId={appealId} hideDropdown />
      <hr {...hrStyling} />

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
      <div {...twoColumnContainerStyling}>
        <div className="cf-push-left" {...css(marginRight(2), leftColumnStyling)}>
          <CheckboxGroup
            hideLabel vertical
            name={COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
            onChange={this.setAreasOfImprovement}
            errorState={highlight && this.qualityIsDeficient() && _.isEmpty(this.state.areas_for_improvement)}
            value={this.state.areas_for_improvement}
            options={this.getDisplayOptions('areas_for_improvement')} />
        </div>
        <div className="cf-push-left">
          <CheckboxGroup
            hideLabel vertical
            name={COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
            onChange={this.setStateAttrList}
            value={this.state.factors_not_considered}
            options={this.getDisplayOptions('factors_not_considered')} />
        </div>
      </div>

      <hr {...hrStyling} />

      <h2 {...inlineHeaderStyling}>{COPY.JUDGE_EVALUATE_DECISION_ADDITIONAL_FACTORS_LABEL}</h2>
      <span {...subH2Styling}>Optional</span>
      <h3>{COPY.JUDGE_EVALUATE_DECISION_ADDITIONAL_FACTORS_SUBHEAD}</h3>
      <TextareaField
        name="additional-factors"
        label={COPY.JUDGE_EVALUATE_DECISION_ADDITIONAL_FACTORS_SUBHEAD}
        hideLabel
        value={this.state.comment}
        onChange={(comment) => this.setState({ comment })} />
    </React.Fragment>;
  };
}

EvaluateDecisionView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
  highlight: state.ui.highlightFormItems,
  taskOptions: state.queue.stagedChanges.taskDecision.opts,
  task: tasksForAppealAssignedToUserSelector(state, ownProps)[0],
  decision: state.queue.stagedChanges.taskDecision,
  userRole: state.ui.userRole,
  error: state.ui.messages.error
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  deleteAppeal,
  requestSave
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(EvaluateDecisionView));
