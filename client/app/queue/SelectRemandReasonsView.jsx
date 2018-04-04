import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import decisionViewBase from './components/DecisionViewBase';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import IssueRemandReasonsOptions from './components/IssueRemandReasonsOptions';

import {
  fullWidth,
  REMAND_REASONS
} from './constants';

const subHeadStyling = css({ marginBottom: '2rem' });
const smallBottomMargin = css({ marginBottom: '1rem' });

class SelectRemandReasonsView extends React.Component {
  constructor(props) {
    super(props);

    this.state = { issuesRendered: 1 };
  }

  getBreadcrumb = () => ({
    breadcrumb: 'Select Remand Reasons',
    path: `/tasks/${this.props.appealId}/remands`
  });

  // todo: auto-prepend < to back button text
  getFooterButtons = () => [{
    displayText: '< Go back to Select Dispositions'
  }, {
    displayText: 'Review Draft Decision'
  }];

  getKeyForRow = (rowNumber) => rowNumber;

  // updateIssue = () => {
  //   const selectedReasons = _.filter(this.state, (key, val) => val ? key : false);
  //
  //   this.props.updateEditingAppealIssue(selectedReasons);
  // }

  validateForm = () => true;

  renderIssueOptions = () => {
    const { issues, appealId } = this.props;
    const renderedOptions = _.map(_.range(this.state.issuesRendered), (n) => {
      const { vacols_sequence_id } = issues[n];

      return <IssueRemandReasonsOptions
        appealId={appealId}
        issueId={vacols_sequence_id}
        key={`remand-reasons-options-${vacols_sequence_id}`}
        idx={n} />;
    });

    if (issues.length > 1 && renderedOptions.length < issues.length) {
      renderedOptions.push(
        <Link
          key="show-more"
          onClick={() => this.setState({ issuesRendered: this.state.issuesRendered + 1 })}>
          Show more
        </Link>
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
  const appeal = state.queue.pendingChanges.appeals[ownProps.appealId];
  const issues = appeal.attributes.issues;

  return {
    appeal,
    issues: _.filter(issues, (issue) => issue.disposition === 'Remanded')
  };
};

export default connect(mapStateToProps)(decisionViewBase(SelectRemandReasonsView));
