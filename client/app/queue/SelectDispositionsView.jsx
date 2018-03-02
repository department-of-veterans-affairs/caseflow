import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import StringUtil from '../util/StringUtil';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import IssueList from './components/IssueList';
import Table from '../components/Table';
import SearchableDropdown from '../components/SearchableDropdown';
import Checkbox from '../components/Checkbox';

import {
  cancelEditingAppeal,
  updateAppealIssue,
  pushBreadcrumb
} from './QueueActions';
import { fullWidth } from './constants';
import DecisionViewFooter from './components/DecisionViewFooter';

const marginTop = (n) => css({ marginTop: `${n}rem` });
const marginBottom = (n) => css({ marginBottom: `${n}rem` });
const marginLeft = (n) => css({ marginLeft: `${n}rem` });
const rowStyling = css({
  '& > tbody > tr > td': {
    verticalAlign: 'top',
    '&:nth-of-type(2n + 1)': {
      width: '40%'
    },
    '> div': {
      minHeight: '12rem'
    }
  }
});

// todo: map to VACOLS attrs
const issueDispositionOptions = [
  [1, 'Allowed'],
  [3, 'Remanded'],
  [4, 'Denied'],
  [5, 'Vacated'],
  [6, 'Dismissed, Other'],
  [8, 'Dismissed, Death'],
  [9, 'Withdrawn']
];

class SelectDispositionsView extends React.PureComponent {
  componentDidMount = () => this.props.pushBreadcrumb({
    breadcrumb: 'Select Dispositions',
    path: `/tasks/${this.props.vacolsId}/dispositions`
  });

  componentWillUnmount = () => {
    // todo: if no edits made, cancel_editing
    this.props.cancelEditingAppeal(this.props.vacolsId);
  }

  getFooterButtons = () => [{
    displayText: 'Go back to Select Work Product',
    classNames: ['cf-btn-link'],
    callback: this.props.goToPrevStep
  }, {
    displayText: 'Finish dispositions',
    classNames: ['cf-right-side'],
    callback: this.props.goToNextStep
  }];

  getDispositionsColumn = (issue) => <div>
    <SearchableDropdown
      placeholder="Select Dispositions"
      value={issue.disposition}
      hideLabel
      searchable={false}
      options={issueDispositionOptions.map((opt) => ({
        label: `${opt[0]} - ${opt[1]}`,
        value: StringUtil.convertToCamelCase(opt[1])
      }))}
      onChange={({ value }) => this.props.updateAppealIssue(
        this.props.vacolsId,
        issue.id,
        {
          disposition: value,
          duplicate: false
        }
      )}
      name="Dispositions dropdown" />
    {issue.disposition === 'vacated' && <Checkbox
      name="duplicate-vacated-issue"
      styling={css(marginBottom(0), marginTop(1))}
      value={issue.duplicate}
      onChange={(duplicate) => this.props.updateAppealIssue(
        this.props.vacolsId,
        issue.id,
        { duplicate }
      )}
      label="Vacate and readjudicate this issue. Automatically duplicate vacated issue." />}
  </div>;

  getKeyForRow = (rowNumber) => rowNumber;
  getColumns = () => [
    {
      header: 'Issues',
      valueFunction: (issue, idx) => <IssueList
        appeal={{ issues: [issue] }}
        issuesOnly
        singleIssue
        idxToDisplay={idx + 1} />
    },
    {
      header: 'Actions',
      valueFunction: () => <Link>Edit Issue</Link>
    },
    {
      header: 'Dispositions',
      valueFunction: this.getDispositionsColumn
    }
  ];

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
  pushBreadcrumb
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(SelectDispositionsView);
