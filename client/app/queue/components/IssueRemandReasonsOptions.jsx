import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import CheckboxGroup from '../../components/CheckboxGroup';

import {
  getIssueProgramDescription,
  getIssueTypeDescription
} from '../utils';
import {
  startEditingAppealIssue,
  updateEditingAppealIssue,
  saveEditedAppealIssue
} from '../QueueActions';
import {
  fullWidth,
  REMAND_REASONS
} from '../constants';

const subHeadStyling = css({ marginBottom: '2rem' });
const smallBottomMargin = css({ marginBottom: '1rem' });
const flexContainer = css({
  display: 'flex',
  maxWidth: '75rem'
});
const flexColumn = css({
  flexDirection: 'row',
  flexWrap: 'wrap',
  '@media(max-width: 768px)': { width: '100%' },
  '@media(min-width: 769px)': { width: '50%' }
});

class IssueRemandReasonsOptions extends React.PureComponent {
  toggleRemandReason = (reasonId) => {
    const updatedReasons = _.get(this.props.issue, 'remand_reasons', []);
    const reasonIdx = _.map(updatedReasons, 'code').indexOf(reasonId);

    if (reasonIdx > -1) {
      updatedReasons.splice(reasonIdx, 1);
    } else {
      updatedReasons.push({
        code: reasonId,
        after_certification: false
      });
    }

    this.updateIssue({ remand_reasons: updatedReasons });
  }

  getIssueRemandOptionsByGroup = (groupName) => {
    const remandReasons = _.map(_.get(this.props.issue, 'remand_reasons', []), 'code');
    const group = REMAND_REASONS[groupName];
    const optionIds = _.map(group, 'id');

    return _.fromPairs(_.zip(
      optionIds,
      _.map(optionIds, (reasonId) => remandReasons.includes(reasonId))
    ));
  }

  updateIssue = (attributes) => {
    const { appealId, issueId } = this.props;

    this.props.startEditingAppealIssue(appealId, issueId);
    this.props.updateEditingAppealIssue(attributes);
    this.props.saveEditedAppealIssue(appealId);
  };

  render = () => {
    const {
      issue,
      idx
    } = this.props;

    return <div key={`remand-reasons-${issue.vacols_sequence_id}`}>
      <h2 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>Issue {idx + 1}</h2>
      <div>Program: {getIssueProgramDescription(issue)}</div>
      <div>Issue: {getIssueTypeDescription(issue)}</div>
      <div>Code: {_.last(issue.description)}</div>
      <div>Certified: {new Date().toISOString().split('T')[0]}</div>

      <div {...flexContainer}>
        <div {...flexColumn}>
          <CheckboxGroup
            label={<h3>Medical examination and opinion</h3>}
            name="med-exam"
            options={REMAND_REASONS.medicalExam}
            onChange={(event) => this.toggleRemandReason(event.target.id)}
            values={this.getIssueRemandOptionsByGroup('medicalExam')} />
          <CheckboxGroup
            label={<h3>Duty to assist records request</h3>}
            name="duty-to-assist"
            options={REMAND_REASONS.dutyToAssistRecordsRequest}
            onChange={(event) => this.toggleRemandReason(event.target.id)}
            values={this.getIssueRemandOptionsByGroup('dutyToAssistRecordsRequest')} />
        </div>
        {/* todo: better CheckboxGroup y alignment */}
        <div {...flexColumn}>
          <CheckboxGroup
            label={<h3>Duty to notify</h3>}
            name="duty-to-notify"
            options={REMAND_REASONS.dutyToNotify}
            onChange={(event) => this.toggleRemandReason(event.target.id)}
            values={this.getIssueRemandOptionsByGroup('dutyToNotify')} />
          <CheckboxGroup
            label={<h3>Due process</h3>}
            name="due-process"
            options={REMAND_REASONS.dueProcess}
            onChange={(event) => this.toggleRemandReason(event.target.id)}
            values={this.getIssueRemandOptionsByGroup('dueProcess')} />
        </div>
      </div>
    </div>;
  };
}

IssueRemandReasonsOptions.propTypes = {
  appealId: PropTypes.string.isRequired,
  issueId: PropTypes.number.isRequired,
  idx: PropTypes.number.isRequired
};

const mapStateToProps = (state, ownProps) => {
  const appeal = state.queue.pendingChanges.appeals[ownProps.appealId];
  const issues = appeal.attributes.issues;

  return {
    issue: _.find(issues, (issue) => issue.vacols_sequence_id === ownProps.issueId)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  startEditingAppealIssue,
  updateEditingAppealIssue,
  saveEditedAppealIssue
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(IssueRemandReasonsOptions);
