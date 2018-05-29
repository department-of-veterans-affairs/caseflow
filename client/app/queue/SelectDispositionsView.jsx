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
import { getUndecidedIssues } from './utils';
import { fullWidth, PAGE_TITLES } from './constants';

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
const smallTopMargin = css({ marginTop: '1rem' });

class SelectDispositionsView extends React.PureComponent {
  getPageName = () => PAGE_TITLES.DISPOSITIONS[this.props.userRole.toUpperCase()];

  getBreadcrumb = () => ({
    breadcrumb: this.getPageName(),
    path: `/queue/appeals/${this.props.vacolsId}/dispositions`
  });

  getNextStepUrl = () => {
    const {
      vacolsId,
      userRole,
      appeal: {
        attributes: { issues }
      }
    } = this.props;
    let nextStep;
    const baseUrl = `/queue/appeals/${vacolsId}`;

    if (_.map(issues, 'disposition').includes('remanded')) {
      nextStep = 'remands';
    } else if (userRole === 'Judge') {
      nextStep = 'evaluate';
    } else {
      nextStep = 'submit';
    }

    return `${baseUrl}/${nextStep}`;
  }

  componentWillUnmount = () => this.props.hideSuccessMessage();
  componentDidMount = () => this.props.setDecisionOptions({ work_product: 'Decision' });

  updateIssue = (issueId, attributes) => {
    const { vacolsId } = this.props;

    this.props.startEditingAppealIssue(vacolsId, issueId, attributes);
    this.props.saveEditedAppealIssue(vacolsId);
  };

  validateForm = () => {
    const { appeal: { attributes: { issues } } } = this.props;
    const issuesWithoutDisposition = _.filter(issues, (issue) => _.isNull(issue.disposition));

    return !issuesWithoutDisposition.length;
  };

  getKeyForRow = (rowNumber) => rowNumber;
  getColumns = () => [{
    header: 'Issues',
    valueFunction: (issue, idx) => <IssueList
      appeal={{ issues: [issue] }}
      idxToDisplay={idx + 1}
      showDisposition={false}
      stretchToFullWidth />
  }, {
    header: 'Actions',
    valueFunction: (issue) => <Link
      to={`/queue/appeals/${this.props.vacolsId}/dispositions/edit/${issue.vacols_sequence_id}`}
    >
      Edit Issue
    </Link>
  }, {
    header: 'Dispositions',
    valueFunction: (issue) => <SelectIssueDispositionDropdown
      updateIssue={_.partial(this.updateIssue, issue.vacols_sequence_id)}
      issue={issue}
      vacolsId={this.props.vacolsId} />
  }];

  render = () => {
    const {
      saveResult,
      vacolsId,
      appeal: { attributes: { issues } }
    } = this.props;

    return <React.Fragment>
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        {this.getPageName()}
      </h1>
      <p className="cf-lead-paragraph" {...marginBottom(2)}>
        Review each issue and assign the appropriate dispositions.
      </p>
      {saveResult && <Alert type="success" title={saveResult} styling={smallTopMargin} />}
      <hr />
      <Table
        columns={this.getColumns}
        rowObjects={getUndecidedIssues(issues)}
        getKeyForRow={this.getKeyForRow}
        styling={tableStyling}
        bodyStyling={tbodyStyling}
      />
      <div {...marginLeft(1.5)}>
        <Link to={`/queue/appeals/${vacolsId}/dispositions/add`}>Add Issue</Link>
      </div>
    </React.Fragment>;
  };
}

SelectDispositionsView.propTypes = {
  vacolsId: PropTypes.string.isRequired,
  userRole: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.vacolsId],
  saveResult: state.ui.messages.success,
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
