import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import decisionViewBase from './components/DecisionViewBase';
import IssueRemandReasonsOptions from './components/IssueRemandReasonsOptions';

import { fullWidth } from './constants';
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

  getBreadcrumb = () => ({
    breadcrumb: 'Select Remand Reasons',
    path: `/tasks/${this.props.appealId}/remands`
  });

  getFooterButtons = () => {
    const { issues } = this.props;
    const { issuesRendered } = this.state;

    return [{
      displayText: 'Go back to Select Dispositions'
    }, {
      displayText: issuesRendered < issues.length ? 'Next Issue' : 'Continue'
    }];
  }

  goToNextStep = () => {
    const { issues } = this.props;
    const { issuesRendered } = this.state;

    if (issuesRendered < issues.length) {
      this.setState({ issuesRendered: Math.min(issuesRendered + 1, issues.length) });

      return false;
    }

    return true;
  }

  validateForm = () => _.every(this.state.renderedChildren, (child) => _.invoke(child, 'validateChosenOptions'));

  getChildRef = (ref) => this.setState({
    renderedChildren: this.state.renderedChildren.concat(ref.getWrappedInstance())
  });

  render = () => <React.Fragment>
    <h1 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
      Select Remand Reasons
    </h1>
    <p className="cf-lead-paragraph" {...subHeadStyling}>
      Please select the appropriate remand reason(s) for all the remand dispositions.
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
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => {
  const appeal = state.queue.pendingChanges.appeals[ownProps.appealId];
  const issues = appeal.attributes.issues;

  return {
    appeal,
    issues: _.filter(issues, (issue) => issue.disposition === 'Remanded')
  };
};

export default connect(mapStateToProps)(decisionViewBase(SelectRemandReasonsView));
