import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import StringUtil from '../util/StringUtil';
import _ from 'lodash';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import IssueList from './components/IssueList';
import Table from '../components/Table';
import SearchableDropdown from '../components/SearchableDropdown';

import { cancelEditingAppeal, updateAppealIssue } from './QueueActions';
import { fullWidth } from './constants';

const mediumBottomMargin = css({ marginBottom: '2rem' });
const smallBottomMargin = css({ marginBottom: '1rem' });
const rowStyling = css({
  '& > tbody > tr > td:first-of-type': {
    width: '40%'
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
  componentWillUnmount = () => {
    // todo: if no edits made, cancel_editing
    this.props.cancelEditingAppeal(this.props.vacolsId);
  }

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
      valueFunction: (issue) => <SearchableDropdown
        placeholder="Select Dispositions"
        value={issue.disposition}
        hideLabel
        searchable={false}
        options={issueDispositionOptions.map((opt) => ({
          label: `${opt[0]} - ${opt[1]}`,
          value: StringUtil.convertToCamelCase(opt[1])
        }))}
        onChange={(({ value }) => this.props.updateAppealIssue(
          this.props.vacolsId,
          issue.id,
          { disposition: value }
        ))}
        name="Dispositions dropdown" />
    }
  ];

  render = () => <AppSegment filledBackground>
    <h1 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
      Select Dispositions
    </h1>
    <p className="cf-lead-paragraph" {...mediumBottomMargin}>
      Review each issue and assign the appropriate dispositions.
    </p>
    <hr />
    <Table
      columns={this.getColumns}
      rowObjects={this.props.appeal.attributes.issues}
      getKeyForRow={this.getKeyForRow}
      styling={rowStyling}
    />
  </AppSegment>;
}

SelectDispositionsView.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.pendingChanges.appeals[ownProps.vacolsId]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  cancelEditingAppeal,
  updateAppealIssue
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(SelectDispositionsView);
