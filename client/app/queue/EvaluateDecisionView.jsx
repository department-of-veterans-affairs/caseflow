import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';
import moment from 'moment';

import decisionViewBase from './components/DecisionViewBase';
import RadioField from '../components/RadioField';
import CheckboxGroup from '../components/CheckboxGroup';
import TextareaField from '../components/TextareaField';

import COPY from '../../../COPY.json';
import { fullWidth, marginBottom, marginTop, marginRight } from './constants';
const mediumSizeText = css({ fontSize: 'medium' });
const headerColumnStyle = css(mediumSizeText, {
  float: 'left',
  width: '31%',
  '&:not(:last-of-type)': {
    marginRight: '2%'
  },
  '> h3': marginBottom(0.5)
});
const headerColumnsContainerStyle = css(fullWidth, {
  display: 'inline-block'
});
const hrStyling = css(marginTop(2), marginBottom(3));

class EvaluateDecisionView extends React.PureComponent {
  render = () => {
    const {
      appeal: { attributes: appeal },
      task: { attributes: task },
      docCount
    } = this.props;
    const daysWorked = moment().startOf('day').diff(moment(task.assigned_on), 'days');

    return <React.Fragment>
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        Evaluate Decision - {appeal.veteran_full_name}
      </h1>
      <p className="cf-lead-paragraph" {...mediumSizeText}>
        Counsel: {task.assigned_by_first_name} {task.assigned_by_last_name}<br />
        Document ID: {task.document_id}
      </p>
      <div {...headerColumnsContainerStyle}>
        <div {...headerColumnStyle}>
          <h3>Case details</h3>
          Docket number: {appeal.docket_number}<br />
          Number of issues: {appeal.issues.length}<br />
          Number of documents: {docCount}
        </div>
        <div {...headerColumnStyle}>
          <h3>Timeliness</h3>
          Date assigned: {}<br />
          Decision submitted: {}<br />
          Calendar days worked: {daysWorked}<br />
        </div>
        <div {...headerColumnStyle}>
          <h3>Notes from the attorney</h3>
          <p>{appeal.note}</p>
        </div>
      </div>

      <hr {...hrStyling} />

      <h3>{COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_LABEL}</h3>
      <RadioField vertical hideLabel
        name={COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_LABEL}
        onChange={_.noop}
        options={[{
          value: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_EASY.toLowerCase(),
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_EASY
        }, {
          value: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_MEDIUM.toLowerCase(),
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_MEDIUM
        }, {
          value: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_HARD.toLowerCase(),
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_HARD
        }]} />

      <h3>{COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_LABEL}</h3>
      <RadioField vertical hideLabel
        name={COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_LABEL}
        onChange={_.noop}
        options={[{
          value: '5',
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_5
        }, {
          value: '4',
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_4
        }, {
          value: '3',
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_3
        }, {
          value: '2',
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_2
        }, {
          value: '1',
          displayText: COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_1
        }]} />

      <div className="cf-push-left" {...marginRight(2)}>
        <h4>{COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_LABEL}</h4>
        <CheckboxGroup
          hideLabel vertical
          name={COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_LABEL}
          onChange={_.noop}
          options={[{
            id: 'theory-contention',
            label: COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_THEORY
          }, {
            id: 'case-law',
            label: COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_CASELAW
          }, {
            id: 'statue-regulation',
            label: COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_STATUE
          }, {
            id: 'admin-procedure',
            label: COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_ADMIN
          }, {
            id: 'relevant-records',
            label: COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_RELEVANT
          }, {
            id: 'lay-evidence',
            label: COPY.JUDGE_EVALUATE_DECISION_FACTORS_NOT_CONSIDERED_LAY
          }]} />
      </div>
      <div className="cf-push-left">
        <h4>{COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}</h4>
        <CheckboxGroup
          hideLabel vertical
          name={COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
          onChange={_.noop}
          options={[{
            id: 'improperly-addressed',
            label: COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_IMPROPERLY_ADDRESSED
          }, {
            id: 'findings-not-supported',
            label: COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_FINDINGS_NOT_SUPPORTED
          }, {
            id: 'due-process',
            label: COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_DUE_PROCESS
          }, {
            id: 'incomplete-remands',
            label: COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_INCOMPLETE_REMANDS
          }, {
            id: 'errors',
            label: COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_ERRORS
          }]} />
      </div>

      <h4>{COPY.JUDGE_EVALUATE_DECISION_ADDITIONAL_FACTORS_LABEL}</h4>
      <TextareaField
        name="additional-factors"
        label={COPY.JUDGE_EVALUATE_DECISION_ADDITIONAL_FACTORS_LABEL}
        hideLabel
        onChange={_.noop} />
    </React.Fragment>;
  };
}

EvaluateDecisionView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.appealId],
  task: state.queue.loadedQueue.tasks[ownProps.appealId],
  docCount: state.queue.docCountForAppeal[ownProps.appealId] || 0
});

export default connect(mapStateToProps)(decisionViewBase(EvaluateDecisionView));
