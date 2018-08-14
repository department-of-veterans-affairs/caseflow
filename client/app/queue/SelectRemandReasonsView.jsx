import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';
import COPY from '../../COPY.json';

import decisionViewBase from './components/DecisionViewBase';
import IssueRemandReasonsOptions from './components/IssueRemandReasonsOptions';

import {
  fullWidth,
  ISSUE_DISPOSITIONS,
  PAGE_TITLES,
  USER_ROLES
} from './constants';
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
    const { appealId, userRole } = this.props;
    const baseUrl = `/queue/appeals/${appealId}`;

    return `${baseUrl}/${userRole === USER_ROLES.JUDGE ? 'evaluate' : 'submit'}`;
  }

  goToPrevStep = () => _.each(this.state.renderedChildren, (child) => child.updateStoreIssue());

  goToNextStep = () => {
    const { issues } = this.props;
    const {
      issuesRendered,
      renderedChildren
    } = this.state;

    if (issuesRendered < issues.length) {
      this.setState({ issuesRendered: Math.min(issuesRendered + 1, issues.length) });

      return false;
    }

    _.each(renderedChildren, (child) => child.updateStoreIssue());

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
      renderedChildren: this.state.renderedChildren.concat(ref.getWrappedInstance())
    });
  }

  render = () => <React.Fragment>
    <h1 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
      {this.getPageName()}
    </h1>
    <p className="cf-lead-paragraph" {...subHeadStyling}>
      {sprintf(
        COPY.REMAND_REASONS_SCREEN_SUBHEAD_LABEL,
        this.props.userRole === USER_ROLES.ATTORNEY ? 'select' : 'review'
      )}
    </p>
    <hr />
    {_.map(_.range(this.state.issuesRendered), (idx) =>
      <IssueRemandReasonsOptions
        appealId={this.props.appealId}
        issueId={this.props.issues[idx].vacols_sequence_id}
        key={`remand-reasons-options-${idx}`}
        ref={this.getChildRef}
        idx={idx} />
    )}
  </React.Fragment>;
}

SelectRemandReasonsView.propTypes = {
  appealId: PropTypes.string.isRequired,
  userRole: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => {
  const appeal = state.queue.stagedChanges.appeals[ownProps.appealId];
  const issues = appeal.issues;

  return {
    appeal,
    issues: _.filter(issues, (issue) => issue.disposition === ISSUE_DISPOSITIONS.REMANDED),
    ..._.pick(state.ui, 'userRole')
  };
};

export default connect(mapStateToProps)(decisionViewBase(SelectRemandReasonsView));
