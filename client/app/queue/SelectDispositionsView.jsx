import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';

import decisionViewBase from './components/DecisionViewBase';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import IssueList from './components/IssueList';
import SelectIssueDispositionDropdown from './components/SelectIssueDispositionDropdown';
import Table from '../components/Table';

import {
  updateEditingAppealIssue,
  setDecisionOptions,
  startEditingAppealIssue,
  saveEditedAppealIssue
} from './QueueActions';
import { highlightInvalidFormItems } from './uiReducer/uiActions';
import { fullWidth } from './constants';

const marginBottom = (margin) => css({ marginBottom: `${margin}rem` });
const marginLeft = (margin) => css({ marginLeft: `${margin}rem` });
const tableStyling = css({
  '& tr': {
    borderBottom: 'none'
  }
});
const tbodyStyling = css({
  '& > tr > td': {
    verticalAlign: 'top',
    paddingTop: '2rem',
    '&:first-of-type': {
      width: '40%'
    },
    '&:last-of-type': {
      width: '35%'
    }
  }
});

class SelectDispositionsView extends React.PureComponent {
  getBreadcrumb = () => ({
    breadcrumb: 'Select Dispositions',
    path: `/tasks/${this.props.vacolsId}/dispositions`
  });

  componentDidMount = () => this.props.setDecisionOptions({ work_product: 'Decision' });

  updateIssue = (issueId, attributes) => {
    const { vacolsId } = this.props;

    this.props.startEditingAppealIssue(vacolsId, issueId);
    this.props.updateEditingAppealIssue(attributes);
    this.props.saveEditedAppealIssue(vacolsId);
  }

  validateForm = () => {
    const { appeal: { attributes: { issues } } } = this.props;
    const issuesWithoutDisposition = _.filter(issues, (issue) => _.isNull(issue.disposition));

    return !issuesWithoutDisposition.length;
  };

  getFooterButtons = () => [{
    displayText: `< Go back to ${this.props.appeal.attributes.veteran_full_name} (${this.props.vbmsId})`
  }, {
    displayText: 'Finish dispositions',
    id: 'finish-dispositions'
  }];

  getKeyForRow = (rowNumber) => rowNumber;
  getColumns = () => [{
    header: 'Issues',
    valueFunction: (issue, idx) => <IssueList appeal={{ issues: [issue] }} idxToDisplay={idx + 1} />
  }, {
    header: 'Actions',
    valueFunction: (issue) => <Link to={`/tasks/${this.props.vacolsId}/dispositions/edit/${issue.vacols_sequence_id}`}>
      Edit Issue
    </Link>
  }, {
    header: 'Dispositions',
    valueFunction: (issue) => <SelectIssueDispositionDropdown
      updateIssue={_.partial(this.updateIssue, issue.vacols_sequence_id)}
      issue={issue}
      vacolsId={this.props.vacolsId} />
  }];

  render = () => <React.Fragment>
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
      styling={tableStyling}
      bodyStyling={tbodyStyling}
    />
    <div {...marginLeft(1.5)}>
      <Link>Add Issue</Link>
    </div>
  </React.Fragment>;
}

SelectDispositionsView.propTypes = {
  vacolsId: PropTypes.string.isRequired,
  vbmsId: PropTypes.string.isRequired,
  prevStep: PropTypes.string.isRequired,
  nextStep: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.pendingChanges.appeals[ownProps.vacolsId]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateEditingAppealIssue,
  highlightInvalidFormItems,
  setDecisionOptions,
  startEditingAppealIssue,
  saveEditedAppealIssue
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SelectDispositionsView));
