import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';
import COPY from '../../COPY';

import IssueRemandReasonsOptions from './components/IssueRemandReasonsOptions';
import {
  editStagedAppeal
} from './QueueActions';
import {
  fullWidth,
  VACOLS_DISPOSITIONS,
  ISSUE_DISPOSITIONS,
  PAGE_TITLES
} from './constants';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES';
import QueueFlowPage from './components/QueueFlowPage';
const subHeadStyling = css({ marginBottom: '2rem' });
const smallBottomMargin = css({ marginBottom: '1rem' });

class SelectRemandReasonsView extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      issuesRendered: 1,
      renderedChildren: []
    };
  }

  getPageName = () => PAGE_TITLES.REMANDS[this.props.userRole.toUpperCase()];

  getNextStepUrl = () => {
    const { appealId, checkoutFlow, taskId } = this.props;
    const baseUrl = `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}`;

    return `${baseUrl}/${checkoutFlow === 'dispatch_decision' ? 'evaluate' : 'submit'}`;
  }

  goToPrevStep = () => _.each(this.state.renderedChildren, (child) => child.updateStoreIssue());

  goToNextStep = () => {
    const { issues, appealId, appeal } = this.props;
    const {
      issuesRendered,
      renderedChildren
    } = this.state;

    if (issuesRendered < issues.length) {
      this.setState({ issuesRendered: Math.min(issuesRendered + 1, issues.length) });

      return false;
    }

    const updatedIssues = _.map(renderedChildren, (child) => child.updateStoreIssue());

    const appealIssues = appeal.isLegacyAppeal ? appeal.issues : appeal.decisionIssues;

    const mergedIssueUpdates = _.map(appealIssues, (issue) => {
      const updatedIssue = _.find(updatedIssues, { id: issue.id });

      if (updatedIssue) {
        issue.remand_reasons = updatedIssue.remand_reasons;
      }

      return issue;
    });

    const attributes = appeal.isLegacyAppeal ? { issues: mergedIssueUpdates } : { decisionIssues: mergedIssueUpdates };

    this.props.editStagedAppeal(appealId, attributes);

    return true;
  }

  validateForm = () => {
    const invalidReasons = _.reject(this.state.renderedChildren, (child) => _.invoke(child, 'validate'));

    if (invalidReasons.length) {
      invalidReasons[0].scrollToWarning();
    }

    return !invalidReasons.length;
  }

  getChildRef = (ref) => {
    if (!ref) {
      return;
    }

    this.setState({
      renderedChildren: [...this.state.renderedChildren, ref]
    });
  }

  render = () => <QueueFlowPage
    getNextStepUrl={this.getNextStepUrl}
    goToNextStep={this.goToNextStep}
    goToPrevStep={this.goToPrevStep}
    validateForm={this.validateForm}
    {...this.props}
  >
    <h1 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
      {this.getPageName()}
    </h1>
    <p className="cf-lead-paragraph" {...subHeadStyling}>
      {sprintf(
        COPY.REMAND_REASONS_SCREEN_SUBHEAD_LABEL,
        this.props.userRole === USER_ROLE_TYPES.attorney ? 'select' : 'review'
      )}
    </p>
    <hr />
    {_.map(_.range(this.state.issuesRendered), (idx) =>
      <IssueRemandReasonsOptions
        appealId={this.props.appealId}
        issueId={this.props.issues[idx].id}
        key={`remand-reasons-options-${idx}`}
        ref={this.getChildRef}
        idx={idx}
        featureToggles={this.props.featureToggles} />
    )}
  </QueueFlowPage>;
}

SelectRemandReasonsView.propTypes = {
  appeal: PropTypes.shape({
    issues: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string
      })
    ),
    decisionIssues: PropTypes.array,
    isLegacyAppeal: PropTypes.bool
  }),
  issues: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string
    })
  ),
  appealId: PropTypes.string.isRequired,
  taskId: PropTypes.string.isRequired,
  checkoutFlow: PropTypes.string.isRequired,
  userRole: PropTypes.string.isRequired,
  editStagedAppeal: PropTypes.func,
  featureToggles: PropTypes.object.isRequired
};

const mapStateToProps = (state, ownProps) => {
  const appeal = state.queue.stagedChanges.appeals[ownProps.appealId];
  let issues;

  if (appeal && appeal.isLegacyAppeal) {
    issues = appeal.issues;
  } else if (appeal) {
    issues = appeal.decisionIssues;
  }

  return {
    appeal,
    issues: _.filter(issues, (issue) => [
      VACOLS_DISPOSITIONS.REMANDED, ISSUE_DISPOSITIONS.REMANDED
    ].includes(issue.disposition)),
    ..._.pick(state.ui, 'userRole')
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  editStagedAppeal
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(SelectRemandReasonsView);
