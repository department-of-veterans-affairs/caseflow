import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import decisionViewBase from './components/DecisionViewBase';
import Button from '../components/Button';
import IssueRemandReasonsOptions from './components/IssueRemandReasonsOptions';

import { fullWidth } from './constants';
const subHeadStyling = css({ marginBottom: '2rem' });
const smallBottomMargin = css({ marginBottom: '1rem' });

class SelectRemandReasonsView extends React.Component {
  constructor(props) {
    super(props);

    this.state = { issuesRendered: 1 };
  }

  getBreadcrumb = () => ({
    breadcrumb: 'Select Remand Reasons',
    path: `/appeals/${this.props.appealId}/remands`
  });

  getFooterButtons = () => [{
    displayText: 'Go back to Select Dispositions'
  }, {
    displayText: 'Review Draft Decision'
  }];

  validateForm = () => true;

  renderIssueOptions = () => {
    const { issues, appealId } = this.props;
    const renderedOptions = _.map(_.range(this.state.issuesRendered), (idx) => {
      const { vacols_sequence_id: issueId } = issues[idx];

      return <IssueRemandReasonsOptions
        appealId={appealId}
        issueId={issueId}
        key={`remand-reasons-options-${issueId}`}
        idx={idx} />;
    });

    if (issues.length > 1 && renderedOptions.length < issues.length) {
      renderedOptions.push(
        <Button
          willNeverBeLoading
          linkStyling
          key="show-more"
          onClick={() => this.setState({ issuesRendered: Math.min(this.state.issuesRendered + 2, issues.length) })}>
          Show more
        </Button>
      );
    }

    return renderedOptions;
  };

  render = () => <React.Fragment>
    <h1 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
      Select Remand Reasons
    </h1>
    <p className="cf-lead-paragraph" {...subHeadStyling}>
      Please select the appropriate remand reason(s) for all the remand dispositions.
    </p>
    <hr />
    {this.renderIssueOptions()}
  </React.Fragment>;
}

SelectRemandReasonsView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => {
  const appeal = state.queue.stagedChanges.appeals[ownProps.appealId];
  const issues = appeal.attributes.issues;

  return {
    appeal,
    issues: _.filter(issues, (issue) => issue.disposition === 'Remanded')
  };
};

export default connect(mapStateToProps)(decisionViewBase(SelectRemandReasonsView));
