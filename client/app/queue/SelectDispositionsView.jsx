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
import Alert from '../components/Alert';

import {
  updateEditingAppealIssue,
  setDecisionOptions,
  startEditingAppealIssue,
  saveEditedAppealIssue
} from './QueueActions';
import { hideSuccessMessage } from './uiReducer/uiActions';
import {
  fullWidth,
  marginBottom,
  marginLeft,
  PAGE_TITLES,
  ISSUE_DISPOSITIONS
} from './constants';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import { getUndecidedIssues } from './utils';

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
const smallTopMargin = css({ marginTop: '1rem' });

class SelectDispositionsView extends React.PureComponent {
  getPageName = () => PAGE_TITLES.DISPOSITIONS[this.props.userRole.toUpperCase()];

  getNextStepUrl = () => {
    const {
      appealId,
      userRole,
      appeal: { issues }
    } = this.props;
    let nextStep;
    const baseUrl = `/queue/appeals/${appealId}`;

    if (_.map(issues, 'disposition').includes(ISSUE_DISPOSITIONS.REMANDED)) {
      nextStep = 'remands';
    } else if (userRole === USER_ROLE_TYPES.judge) {
      nextStep = 'evaluate';
    } else {
      nextStep = 'submit';
    }

    return `${baseUrl}/${nextStep}`;
  }

  getPrevStepUrl = () => {
    const {
      appealId,
      appeal
    } = this.props;

    if (appeal.isLegacyAppeal) {
      return `/queue/appeals/${appealId}`;
    }

    return `/queue/appeals/${appealId}/special_issues`;
  }

  componentWillUnmount = () => this.props.hideSuccessMessage();
  componentDidMount = () => {
    if (this.props.userRole === USER_ROLE_TYPES.attorney) {
      this.props.setDecisionOptions({ work_product: 'Decision' });
    }
  }

  updateIssue = (issueId, attributes) => {
    const { appealId } = this.props;

    this.props.startEditingAppealIssue(appealId, issueId, attributes);
    this.props.saveEditedAppealIssue(appealId);
  };

  validateForm = () => {
    const { appeal: { issues } } = this.props;
    const issuesWithoutDisposition = _.reject(issues, 'disposition');

    return !issuesWithoutDisposition.length;
  };

  getKeyForRow = (rowNumber) => rowNumber;
  getColumns = () => {
    const {
      appeal,
      appealId
    } = this.props;

    const columns = [{
      header: 'Issues',
      valueFunction: (issue, idx) => <IssueList
        appeal={{ issues: [issue] }}
        idxToDisplay={idx + 1}
        showDisposition={false}
        stretchToFullWidth />
    }, {
      header: 'Dispositions',
      valueFunction: (issue) => <SelectIssueDispositionDropdown
        updateIssue={_.partial(this.updateIssue, issue.id)}
        issue={issue}
        appeal={appeal} />
    }];

    if (appeal.isLegacyAppeal) {
      columns.splice(1, 0, {
        header: 'Actions',
        valueFunction: (issue) => <Link to={`/queue/appeals/${appealId}/dispositions/edit/${issue.id}`}>
          Edit Issue
        </Link>
      });
    }

    return columns;
  };

  render = () => {
    const {
      success,
      appealId,
      appeal,
      appeal: { issues }
    } = this.props;

    return <React.Fragment>
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        {this.getPageName()}
      </h1>
      <p className="cf-lead-paragraph" {...marginBottom(2)}>
        Review each issue and assign the appropriate dispositions.
      </p>
      {success && <Alert type="success" title={success.title} message={success.detail} styling={smallTopMargin} />}
      <hr />
      <Table
        columns={this.getColumns}
        rowObjects={getUndecidedIssues(issues)}
        getKeyForRow={this.getKeyForRow}
        styling={tableStyling}
        bodyStyling={tbodyStyling}
      />
      {appeal.isLegacyAppeal && <div {...marginLeft(1.5)}>
        <Link to={`/queue/appeals/${appealId}/dispositions/add`}>Add Issue</Link>
      </div>}
    </React.Fragment>;
  };
}

SelectDispositionsView.propTypes = {
  appealId: PropTypes.string.isRequired,
  userRole: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  success: state.ui.messages.success,
  ..._.pick(state.ui, 'userRole')
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateEditingAppealIssue,
  setDecisionOptions,
  startEditingAppealIssue,
  saveEditedAppealIssue,
  hideSuccessMessage
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SelectDispositionsView));
