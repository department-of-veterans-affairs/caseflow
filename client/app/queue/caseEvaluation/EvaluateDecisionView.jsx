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

import { deleteAppeal } from '../QueueActions';
import { requestSave } from '../uiReducer/uiActions';
import { buildCaseReviewPayload } from '../utils';
import { taskById } from '../selectors';

import COPY from '../../../COPY';
import JUDGE_CASE_REVIEW_OPTIONS from '../../../constants/JUDGE_CASE_REVIEW_OPTIONS';
import DECISION_TYPES from '../../../constants/APPEAL_DECISION_TYPES';
import {
  marginBottom,
  marginTop,
  paddingLeft,
  fullWidth,
  VACOLS_DISPOSITIONS,
  ISSUE_DISPOSITIONS,
  JUDGE_CASE_REVIEW_COMMENT_MAX_LENGTH
} from '../constants';
import DispatchSuccessDetail from '../components/DispatchSuccessDetail';
import QueueFlowPage from '../components/QueueFlowPage';
import { JudgeCaseQuality } from './JudgeCaseQuality';
import { qualityIsDeficient } from '.';

const headerStyling = marginBottom(1.5);
const inlineHeaderStyling = css(headerStyling, { float: 'left' });
const hrStyling = css(marginTop(2), marginBottom(3));
const subH2Styling = css(paddingLeft(1), { lineHeight: 2 });

class EvaluateDecisionView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      one_touch_initiative: false,
      complexity: null,
      quality: null,
      factors_not_considered: {},
      areas_for_improvement: {},
      positive_feedback: {},
      comment: ''
    };

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
    const { areas_for_improvement, factors_not_considered, complexity, quality } = this.state;

    if (!complexity) {
      this.scrollTo(this.complexityLabel.current);

      return false;
    }

    if (!quality) {
      this.scrollTo(this.qualityLabel.current);

      return false;
    }

    // eslint-disable-next-line camelcase
    if (qualityIsDeficient(this.state.quality) && _.every([areas_for_improvement, factors_not_considered], _.isEmpty)) {
      this.scrollTo(this.qualityAlert.current);

      return false;
    }

    return true;
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

  handleCaseQualityChange = (values) => this.setState({ ...values });

  render = () => {
    const { appeal, task, appealId, highlight, error, ...otherProps } = this.props;

    const dateAssigned = moment(task.previousTaskAssignedOn);
    const decisionSubmitted = moment(task.assignedOn);
    const daysWorked = decisionSubmitted.startOf('day').diff(dateAssigned, 'days');

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
          <React.Fragment>
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
          </React.Fragment>
        )}
        <h2 {...headerStyling}>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_LABEL}</h2>
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_ASSIGNED_DATE}</b>: {dateAssigned.format('M/D/YY')}
        <br />
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_SUBMITTED_DATE}</b>: {decisionSubmitted.format('M/D/YY')}
        <br />
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED}</b>&nbsp; (
        {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED_ADDENDUM}): {daysWorked}
        <br />
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
  deleteAppeal: PropTypes.func
};

const mapStateToProps = (state, ownProps) => {
  const appeal = state.queue.stagedChanges.appeals[ownProps.appealId];

  return {
    appeal,
    highlight: state.ui.highlightFormItems,
    taskOptions: state.queue.stagedChanges.taskDecision.opts,
    task: taskById(state, { taskId: ownProps.taskId }),
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
