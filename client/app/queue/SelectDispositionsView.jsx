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
  cancelEditingAppeal,
  updateAppealIssue,
  setDecisionOptions
} from './QueueActions';
import { highlightInvalidFormItems } from './uiReducer/uiActions';
import { fullWidth } from './constants';

const marginBottom = (margin) => css({ marginBottom: `${margin}rem` });
const marginLeft = (margin) => css({ marginLeft: `${margin}rem` });
const tbodyStyling = css({
  '& > tr': {
    borderBottom: 'none',
    '> td': {
      verticalAlign: 'top',
      paddingTop: '2rem',
      '&:first-of-type': {
        width: '40%'
      },
      '&:last-of-type': {
        width: '35%'
      }
    }
  }
});

class SelectDispositionsView extends React.PureComponent {
  getBreadcrumb = () => ({
    breadcrumb: 'Select Dispositions',
    path: `/tasks/${this.props.vacolsId}/dispositions`
  });

  componentDidMount = () => {
    const {
      vacolsId,
      appeal: { attributes: { issues } }
    } = this.props;

    // Wipe any previously-set dispositions in the pending
    // appeal's issues for validation purposes.
    _.each(issues, (issue) =>
      this.props.updateAppealIssue(
        vacolsId,
        issue.id,
        { disposition: null }
      ));

    this.props.setDecisionOptions({ workProduct: 'Decision' });
  };

  goToPrevStep = () => {
    const {
      appeal: { attributes: { issues } },
      vacolsId
    } = this.props;
    const issuesWithoutDisposition = _.filter(issues, (issue) => _.isNull(issue.disposition));

    // If the user hasn't selected a disposition for all issues and they're
    // navigating back to the start, they've canceled the checkout process.
    if (issuesWithoutDisposition.length > 0) {
      this.props.cancelEditingAppeal(vacolsId);
    }

    return true;
  };

  validateForm = () => {
    const { appeal: { attributes: { issues } } } = this.props;
    const issuesWithoutDisposition = _.filter(issues, (issue) => _.isNull(issue.disposition));

    return !issuesWithoutDisposition.length;
  };

  getFooterButtons = () => [{
    displayText: `< Go back to draft decision ${this.props.vbmsId}`
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
    valueFunction: () => <Link>Edit Issue</Link>
  }, {
    header: 'Dispositions',
    valueFunction: (issue) => <SelectIssueDispositionDropdown
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
  cancelEditingAppeal,
  updateAppealIssue,
  highlightInvalidFormItems,
  setDecisionOptions
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SelectDispositionsView));
