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

import Checkbox from '../../components/Checkbox';
import TextareaField from '../../components/TextareaField';
import CaseTitle from '../CaseTitle';
import Alert from '../../components/Alert';
import TaskSnapshot from '../TaskSnapshot';
import RadioField from '../../components/RadioField';

import { deleteAppeal } from '../QueueActions';
import { requestSave } from '../uiReducer/uiActions';
import { buildCaseReviewPayload } from '../utils';
import { taskById,
  getTaskTreesForAttorneyTasks,
  getLegacyTaskTree,
  getAttorneyTasksForJudgeTask,
} from '../selectors';

import COPY from '../../../COPY';
import JUDGE_CASE_REVIEW_OPTIONS from '../../../constants/JUDGE_CASE_REVIEW_OPTIONS';
import DECISION_TYPES from '../../../constants/APPEAL_DECISION_TYPES';
import {
  marginBottom,
  marginTop,
  paddingLeft,
  fullWidth,
  redText,
  VACOLS_DISPOSITIONS,
  ISSUE_DISPOSITIONS,
  JUDGE_CASE_REVIEW_COMMENT_MAX_LENGTH
} from '../constants';
import DispatchSuccessDetail from '../components/DispatchSuccessDetail';
import QueueFlowPage from '../components/QueueFlowPage';
import { JudgeCaseQuality } from './JudgeCaseQuality';
import { qualityIsDeficient, errorStylingNoTopMargin } from '.';
import { AttorneyTaskTimeline } from './AttorneyTaskTimeline';
import { AttorneyDaysWorked } from './AttorneyDaysWorked';

const headerStyling = marginBottom(1.5);
const inlineHeaderStyling = css(headerStyling, { float: 'left' });
const hrStyling = css(marginTop(2), marginBottom(3));
const subH2Styling = css(paddingLeft(1), { lineHeight: 2 });
const caseTimelineStyling = css({ display: 'flex' });
const caseTypeStyling = css({ width: '15%' });

const timelinessOpts = Object.entries(JUDGE_CASE_REVIEW_OPTIONS.TIMELINESS).map(([value, displayText]) => ({
  displayText,
  value
}));

class EvaluateDecisionView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      one_touch_initiative: false,
      timeliness: null,
      complexity: null,
      quality: null,
      factors_not_considered: {},
      areas_for_improvement: {},
      positive_feedback: {},
      comment: ''
    };

    this.timelinessLabel = React.createRef();
    this.complexityLabel = React.createRef();
    this.qualityAlert = React.createRef();
    this.qualityLabel = React.createRef();
  }

  componentDidMount = () => this.setState(_.pick(this.props.taskOptions, _.keys(this.state)));

  // todo: consoldate w/IssueRemandReasonOptions.scrollTo
  scrollTo = (dest = this, opts) =>
    scrollToComponent(
      dest,
      _.defaults(opts, {
        align: 'top',
        duration: 1500,
        ease: 'outCube',
        offset: -10
      })
    );

  validateForm = () => {
    // eslint-disable-next-line camelcase
    const { areas_for_improvement, factors_not_considered, complexity, quality, timeliness } = this.state;
    let isValid = true;

    if (!timeliness && this.props.displayCaseTimelinessQuestion) {
      this.scrollTo(this.timelinessLabel.current);

      isValid = false;
    } else if (!complexity) {
      this.scrollTo(this.complexityLabel.current);

      isValid = false;
    } else if (!quality) {
      this.scrollTo(this.qualityLabel.current);

      isValid = false;
    }

    // eslint-disable-next-line camelcase
    if (qualityIsDeficient(this.state.quality) && _.every([areas_for_improvement, factors_not_considered], _.isEmpty)) {
      this.scrollTo(this.qualityAlert.current);

      isValid = false;
    }

    return isValid;
  };

  getPrevStepUrl = () => {
    const { appealId, taskId, checkoutFlow, appeal } = this.props;
    const prevUrl = `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}`;
    const dispositions = _.map(appeal.issues, (issue) => issue.disposition);
    const remandedIssues = _.some(dispositions, (disposition) =>
      [VACOLS_DISPOSITIONS.REMANDED, ISSUE_DISPOSITIONS.REMANDED].includes(disposition)
    );

    return `${prevUrl}/${remandedIssues ? 'remands' : 'dispositions'}`;
  };

  goToNextStep = () => {
    const { task, appeal, checkoutFlow, decision, appealId } = this.props;

    let loc = 'bva_dispatch';
    let successMsg = sprintf(COPY.JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE, appeal.veteranFullName);

    if (checkoutFlow === DECISION_TYPES.OMO_REQUEST) {
      loc = 'omo_office';
      successMsg = sprintf(COPY.JUDGE_CHECKOUT_OMO_SUCCESS_MESSAGE_TITLE, appeal.veteranFullName);
    }
    const issuesToPass = appeal.isLegacyAppeal ? appeal.issues : appeal.decisionIssues;
    const payload = buildCaseReviewPayload(checkoutFlow, decision, false, issuesToPass, {
      location: loc,
      attorney_id: appeal.isLegacyAppeal ? task.assignedBy.pgId : appeal.assignedAttorney.id,
      isLegacyAppeal: appeal.isLegacyAppeal,
      ...this.state
    });

    this.props.
      requestSave(`/case_reviews/${task.taskId}/complete`, payload, {
        title: successMsg,
        detail: <DispatchSuccessDetail task={task} />
      }).
      then(
        () => this.props.deleteAppeal(appealId),
        (response) => {
          // eslint-disable-next-line no-console
          console.log(response);
        }
      ).
      catch(() => {
        // handle the error from the frontend
      });
  };

  getDisplayOptions = (opts) =>
    _.map(JUDGE_CASE_REVIEW_OPTIONS[opts.toUpperCase()], (value, key) => ({
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
  };

  renderAttorneyTasksTreeTimeline = (appeal, attorneyTaskTree, index) => {
    const { attorneyTask, childrenTasks } = attorneyTaskTree;
    const dateAssigned = moment(attorneyTask.createdAt);
    const dateClosed = moment(attorneyTask.closedAt);

    let displayString = COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_ASSIGNED_DATE;

    if (attorneyTask.type === 'AttorneyRewriteTask') {
      displayString = COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_REASSIGNED_DATE;
    }

    return (
      <div>
        {index > 0 && (<br />)}
        <span>{dateAssigned.format('M/D/YY')} - {displayString}</span>
        <AttorneyTaskTimeline title="Attorney Task Timeline"
          appeal={appeal}
          attorneyChildrenTasks={childrenTasks} />
        <span>
          {dateClosed.format('M/D/YY')} - {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_SUBMITTED_DATE}
        </span>
      </div>
    );
  }

  renderCaseTimeliness = () => {
    const { appeal,
      isLegacy,
      task,
      attorneyChildrenTasks,
      displayCaseTimelinessTimeline,
    } = this.props;

    let dateAssigned = moment(task.previousTaskAssignedOn);
    const decisionSubmitted = moment(task.assignedOn);

    // If DAS Case Timeline is enabled
    if (displayCaseTimelinessTimeline) {
      const caseType = task.caseType;
      const aod = task.aod;
      const cavc = caseType === 'Court Remand';
      let daysAssigned = decisionSubmitted.startOf('day').diff(dateAssigned, 'days') + 1;

      if (isLegacy) {
        return (
          <>
            <div {...caseTimelineStyling} >
              <span {...caseTypeStyling}>
                <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_CASE_TYPE}</b>:
                { aod && <span {...redText}> AOD</span> }
                { cavc && <span {...redText}> CAVC</span> }
                { !aod && !cavc && <span> {caseType}</span> }
              </span>
              <AttorneyDaysWorked
                attorneyTasks={attorneyChildrenTasks}
                daysAssigned={daysAssigned} />
            </div>
            <br />
            <span>{dateAssigned.format('M/D/YY')} - {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_ASSIGNED_DATE}</span>
            <AttorneyTaskTimeline title="Attorney Task Timeline"
              appeal={appeal}
              attorneyChildrenTasks={attorneyChildrenTasks} />
            <span>
              {decisionSubmitted.format('M/D/YY')} - {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_SUBMITTED_DATE}
            </span>
          </>
        );
      }

      const oldestAttorneyTask = attorneyChildrenTasks[0].attorneyTask;

      // If not legacy use oldest attorney task and recalculate total days assigned
      dateAssigned = moment(oldestAttorneyTask.createdAt);
      daysAssigned = decisionSubmitted.startOf('day').diff(dateAssigned, 'days') + 1;
      const allChildrenTasks = [];

      attorneyChildrenTasks.forEach((attorneyTaskTree) => allChildrenTasks.push(...attorneyTaskTree.childrenTasks));

      return (
        <div>
          <div {...caseTimelineStyling} >
            <span {...caseTypeStyling}>
              <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_CASE_TYPE}</b>:
              { aod && <span {...redText}> AOD</span> }
              { cavc && <span {...redText}> CAVC</span> }
              { !aod && !cavc && <span> {caseType}</span> }
            </span>
            <AttorneyDaysWorked
              attorneyTasks={allChildrenTasks}
              daysAssigned={daysAssigned} />
          </div>
          <br />
          {attorneyChildrenTasks.map((attorneyTaskTree, index) =>
            this.renderAttorneyTasksTreeTimeline(appeal, attorneyTaskTree, index))}
        </div>
      );

    }

    const daysWorked = decisionSubmitted.startOf('day').diff(dateAssigned, 'days');

    return (
      <>
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_ASSIGNED_DATE}</b>: {dateAssigned.format('M/D/YY')}
        <br />
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_SUBMITTED_DATE}</b>: {decisionSubmitted.format('M/D/YY')}
        <br />
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED}</b>&nbsp; (
        {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED_ADDENDUM}): {daysWorked}
      </>
    );
  }

  handleCaseQualityChange = (values) => this.setState({ ...values });

  render = () => {
    const { appeal,
      appealId,
      highlight,
      error,
      displayCaseTimelinessQuestion,
      ...otherProps } = this.props;

    return (
      <QueueFlowPage
        appealId={appealId}
        validateForm={this.validateForm}
        goToNextStep={this.goToNextStep}
        getPrevStepUrl={this.getPrevStepUrl}
        {...otherProps}
      >
        <CaseTitle
          heading={appeal.veteranFullName}
          appealId={appealId}
          appeal={this.props.appeal}
          analyticsSource="evaluate_decision"
          taskType="Dispatch"
          redirectUrl={window.location.pathname}
        />
        <h1 {...css(fullWidth, marginBottom(2), marginTop(2))}>{COPY.EVALUATE_DECISION_PAGE_TITLE}</h1>
        {error && (
          <Alert title={error.title} type="error" styling={css(marginTop(0), marginBottom(1))}>
            {error.detail}
          </Alert>
        )}
        <TaskSnapshot appealId={appealId} hideDropdown />
        <hr {...hrStyling} />
        {appeal.isLegacyAppeal && (
          <>
            <h2 {...headerStyling}>{COPY.JUDGE_EVALUATE_DECISION_CASE_ONE_TOUCH_INITIATIVE_LABEL}</h2>
            <Checkbox
              label={<b>{COPY.JUDGE_EVALUATE_DECISION_CASE_ONE_TOUCH_INITIATIVE_SUBHEAD}</b>}
              name="One Touch Initiative"
              value={this.state.one_touch_initiative}
              onChange={(value) => {
                this.setState({ one_touch_initiative: value });
              }}
            />
            <hr {...hrStyling} />
          </>
        )}
        <h2 {...headerStyling} ref={this.timelinessLabel}>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_LABEL}</h2>
        {this.renderCaseTimeliness()}
        <br />
        {displayCaseTimelinessQuestion && (
          <>
            <br />
            <h3>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_SUBHEAD}</h3>
            <RadioField
              vertical
              hideLabel
              name=""
              required
              onChange={(value) => {
                this.setState({ timeliness: value });
              }}
              value={this.state.timeliness}
              styling={css(marginBottom(0), errorStylingNoTopMargin)}
              errorMessage={highlight && !this.state.timeliness ? 'Choose one' : null}
              options={timelinessOpts}
            />
          </>
        )}

        <hr {...hrStyling} />
        <JudgeCaseQuality
          highlight={highlight}
          complexityLabelRef={this.complexityLabel}
          qualityAlertRef={this.qualityAlert}
          qualityLabelRef={this.qualityLabel}
          onChange={(values) => this.handleCaseQualityChange(values)}
        />
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
          onChange={(comment) => this.setState({ comment })}
        />
      </QueueFlowPage>
    );
  };
}

EvaluateDecisionView.propTypes = {
  checkoutFlow: PropTypes.string.isRequired,
  appealId: PropTypes.string.isRequired,
  appeal: PropTypes.object,
  task: PropTypes.object,
  taskId: PropTypes.string,
  decision: PropTypes.object,
  taskOptions: PropTypes.object,
  error: PropTypes.object,
  highlight: PropTypes.bool,
  requestSave: PropTypes.func,
  deleteAppeal: PropTypes.func,
  displayCaseTimelinessQuestion: PropTypes.bool,
  oldestAttorneyTask: PropTypes.object,
  attorneyChildrenTasks: PropTypes.array,
  displayCaseTimelinessTimeline: PropTypes.bool,
  isLegacy: PropTypes.bool,
};

const mapStateToProps = (state, ownProps) => {
  const appeal = state.queue.stagedChanges.appeals[ownProps.appealId];
  let isLegacy;
  let oldestAttorneyTask;
  let attorneyChildrenTasks = [];

  // previousTaskAssignedOn comes from
  // eslint-disable-next-line max-len
  // Legacy: https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/legacy_tasks/judge_legacy_task.rb#L17
  // AMA: https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/tasks/judge_task.rb#L42
  const judgeDecisionReviewTask = taskById(state, { taskId: ownProps.taskId });

  // When canceling out of Evaluate Decision page need to check if appeal exists otherwise failures occur
  if (appeal) {
    isLegacy = appeal.docketName === 'legacy';

    if (isLegacy) {
      attorneyChildrenTasks = getLegacyTaskTree(state, {
        appealId: appeal.externalId, judgeDecisionReviewTask });
    } else {
      // We want the oldest AttorneyTask to use its createdAt as the start of the date range to be displayed and for
      // calculating the total days between JudgeTask and AttorneyTask
      // These tasks are returned sorted so the oldest is at front
      oldestAttorneyTask = getAttorneyTasksForJudgeTask(state, {
        appealId: appeal.externalId, judgeDecisionReviewTaskId: judgeDecisionReviewTask.uniqueId })[0];

      // Get all tasks under the JudgeDecisionReviewTask
      // Filters out those without a closedAt date or that are hideFromCaseTimeline
      attorneyChildrenTasks = getTaskTreesForAttorneyTasks(state, {
        appealId: appeal.externalId, judgeDecisionReviewTaskId: judgeDecisionReviewTask.uniqueId });
    }
  }

  return {
    appeal,
    attorneyChildrenTasks,
    oldestAttorneyTask,
    isLegacy,
    highlight: state.ui.highlightFormItems,
    taskOptions: state.queue.stagedChanges.taskDecision.opts,
    task: judgeDecisionReviewTask,
    decision: state.queue.stagedChanges.taskDecision,
    error: state.ui.messages.error
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      deleteAppeal,
      requestSave
    },
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(EvaluateDecisionView);
