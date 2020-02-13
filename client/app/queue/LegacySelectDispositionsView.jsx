import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';

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
  VACOLS_DISPOSITIONS,
  ISSUE_DISPOSITIONS
} from './constants';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES';
import { getUndecidedIssues } from './utils';
import QueueFlowPage from './components/QueueFlowPage';

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

class LegacySelectDispositionsView extends React.PureComponent {
  decisionReviewCheckoutFlow = () => this.props.checkoutFlow === 'dispatch_decision';

  getPageName = () => PAGE_TITLES.DISPOSITIONS[this.props.userRole.toUpperCase()];

  getNextStepUrl = () => {
    const {
      appealId,
      taskId,
      checkoutFlow,
      appeal: { issues }
    } = this.props;
    let nextStep;
    const dispositions = issues.map((issue) => issue.disposition);
    const remandedIssues = _.some(dispositions, (disp) => [
      VACOLS_DISPOSITIONS.REMANDED, ISSUE_DISPOSITIONS.REMANDED
    ].includes(disp));

    if (remandedIssues) {
      nextStep = 'remands';
    } else if (this.decisionReviewCheckoutFlow()) {
      nextStep = 'evaluate';
    } else {
      nextStep = 'submit';
    }

    return `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/${nextStep}`;
  }

  getPrevStepUrl = () => {
    const {
      appealId,
      appeal,
      taskId,
      checkoutFlow
    } = this.props;

    if (appeal.isLegacyAppeal) {
      return `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/special_issues`;
    }

    return `/queue/appeals/${appealId}`;

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
      taskId,
      checkoutFlow,
      appealId
    } = this.props;

    const columns = [{
      header: 'Issues',
      valueFunction: (issue, idx) => <IssueList
        appeal={{
          issues: [issue],
          isLegacyAppeal: appeal.isLegacyAppeal
        }}
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
        valueFunction: (issue) => {
          return <Link
            replace to={`/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/dispositions/edit/${issue.id}`}
          >
            Edit Issue
          </Link>;
        }
      });
    }

    return columns;
  };

  render = () => {
    const {
      success,
      appealId,
      taskId,
      checkoutFlow,
      appeal,
      appeal: { issues },
      ...otherProps
    } = this.props;

    return <QueueFlowPage
      getNextStepUrl={this.getNextStepUrl}
      getPrevStepUrl={this.getPrevStepUrl}
      validateForm={this.validateForm}
      appealId={appealId}
      {...otherProps}
    >
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
        rowObjects={appeal.isLegacyAppeal ? getUndecidedIssues(issues) : issues}
        getKeyForRow={this.getKeyForRow}
        styling={tableStyling}
        bodyStyling={tbodyStyling}
      />
      {appeal.isLegacyAppeal && <div {...marginLeft(1.5)}>
        <Link
          replace to={`/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/dispositions/add`}
        >Add Issue</Link>
      </div>}
    </QueueFlowPage>;
  };
}

LegacySelectDispositionsView.propTypes = {
  appeal: PropTypes.shape({
    issues: PropTypes.array,
    isLegacyAppeal: PropTypes.bool
  }),
  success: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  appealId: PropTypes.string.isRequired,
  taskId: PropTypes.string.isRequired,
  checkoutFlow: PropTypes.string.isRequired,
  userRole: PropTypes.string.isRequired,
  updateEditingAppealIssue: PropTypes.func,
  setDecisionOptions: PropTypes.func,
  startEditingAppealIssue: PropTypes.func,
  saveEditedAppealIssue: PropTypes.func,
  hideSuccessMessage: PropTypes.func
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

export default connect(mapStateToProps, mapDispatchToProps)(LegacySelectDispositionsView);
