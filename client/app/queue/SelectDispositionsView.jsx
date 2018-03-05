import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import IssueList from './components/IssueList';
import SelectIssueDispositionDropdown from './components/SelectIssueDispositionDropdown';
import Table from '../components/Table';

import {
  cancelEditingAppeal,
  updateAppealIssue,
  pushBreadcrumb,
  highlightMissingDispositions
} from './QueueActions';
import { fullWidth } from './constants';
import DecisionViewFooter from './components/DecisionViewFooter';

const marginBottom = (margin) => css({ marginBottom: `${margin}rem` });
const marginLeft = (margin) => css({ marginLeft: `${margin}rem` });
const rowStyling = css({
  '& > tbody > tr': {
    borderBottom: 'none',
    '> td': {
      verticalAlign: 'top',
      paddingTop: '2rem',
      '&:nth-of-type(2n + 1)': {
        width: '40%'
      },
      '> div': {
        minHeight: '12rem'
      }
    }
  }
});

class SelectDispositionsView extends React.Component {
  componentDidMount = () => {
    const {
      vacolsId,
      appeal: { attributes: { issues } }
    } = this.props;

    this.props.highlightIssueDispositions(false);
    this.props.pushBreadcrumb({
      breadcrumb: 'Select Dispositions',
      path: `/tasks/${vacolsId}/dispositions`
    });
    // Wipe any previously-set dispositions in the pending
    // appeal's issues for validation purposes.
    _.each(issues, (issue) =>
      this.props.updateAppealIssue(
        vacolsId,
        issue.id,
        { disposition: null }
      ));
  };

  componentWillUnmount = () => {
    const {
      appeal: { attributes: { issues } },
      vacolsId
    } = this.props;
    const issuesWithoutDisposition = _.filter(issues, (issue) => _.isNull(issue.disposition));

    // If the user hasn't selected a disposition for all issues and they're
    // navigating away, they've canceled the checkout process.
    if (issuesWithoutDisposition.length > 0) {
      this.props.cancelEditingAppeal(vacolsId);
    }
  }

  getFooterButtons = () => [{
    displayText: 'Go back to Select Work Product',
    classNames: ['cf-btn-link'],
    callback: this.props.goToPrevStep
  }, {
    displayText: 'Finish dispositions',
    classNames: ['cf-right-side'],
    callback: () => {
      const {
        goToNextStep,
        appeal: { attributes: { issues } }
      } = this.props;
      const issuesWithoutDisposition = _.filter(issues, (issue) => _.isNull(issue.disposition));

      if (issuesWithoutDisposition.length === 0) {
        goToNextStep();
      } else {
        this.props.highlightMissingDispositions(true);
      }
    }
  }];

  getKeyForRow = (rowNumber) => rowNumber;
  getColumns = () => [{
    header: 'Issues',
    valueFunction: (issue, idx) => <IssueList
      appeal={{ issues: [issue] }}
      singleIssue
      singleColumn
      idxToDisplay={idx + 1} />
  }, {
    header: 'Actions',
    valueFunction: () => <Link>Edit Issue</Link>
  }, {
    header: 'Dispositions',
    valueFunction: (issue) => <SelectIssueDispositionDropdown
      issue={issue}
      vacolsId={this.props.vacolsId} />
  }];

  render = () => <React.Fragment>
    <AppSegment filledBackground>
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        Select Dispositions
      </h1>
      <p className="cf-lead-paragraph" {...marginBottom(2)}>
        Review each issue and assign the appropriate dispositions.
      </p>
      <hr />
      <Table
        columns={this.getColumns}
        rowObjects={this.props.appeal.attributes.issues}
        getKeyForRow={this.getKeyForRow}
        styling={rowStyling}
      />
      <div {...marginLeft(1.5)}>
        <Link>Add Issue</Link>
      </div>
    </AppSegment>
    <DecisionViewFooter buttons={this.getFooterButtons()} />
  </React.Fragment>;
}

SelectDispositionsView.propTypes = {
  vacolsId: PropTypes.string.isRequired,
  vbmsId: PropTypes.string.isRequired,
  goToNextStep: PropTypes.func.isRequired,
  goToPrevStep: PropTypes.func.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.pendingChanges.appeals[ownProps.vacolsId]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  cancelEditingAppeal,
  updateAppealIssue,
  pushBreadcrumb,
  highlightMissingDispositions
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(SelectDispositionsView);
