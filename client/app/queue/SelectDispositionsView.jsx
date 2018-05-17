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
import { fullWidth, DISPOSITION_ID_BY_PARAMETERIZED } from './constants';

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
  getBreadcrumb = () => ({
    breadcrumb: 'Select Dispositions',
    path: `/queue/appeals/${this.props.vacolsId}/dispositions`
  });

  getNextStepUrl = () => {
    const {
      vacolsId,
      nextStep,
      appeal: {
        attributes: { issues }
      }
    } = this.props;

    return _.map(issues, 'disposition').includes('remanded') ?
      `/queue/appeals/${vacolsId}/remands` : nextStep;
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

    // filter already-decided issues from attorney checkout flow. undecided disposition
    // ids are all numerical (1-9), decided ids are alphabetical (A-X)
    const filteredIssues = _.filter(issues, (issue) =>
      !issue.disposition || Number(DISPOSITION_ID_BY_PARAMETERIZED[issue.disposition])
    );

    return <React.Fragment>
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        Select Dispositions
      </h1>
      <p className="cf-lead-paragraph" {...marginBottom(2)}>
        Review each issue and assign the appropriate dispositions.
      </p>
      {saveResult && <Alert type="success" title={saveResult} styling={smallTopMargin} />}
      <hr />
      <Table
        columns={this.getColumns}
        rowObjects={filteredIssues}
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
  prevStep: PropTypes.string.isRequired,
  nextStep: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.vacolsId],
  saveResult: state.ui.messages.success
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateEditingAppealIssue,
  setDecisionOptions,
  startEditingAppealIssue,
  saveEditedAppealIssue,
  hideSuccessMessage
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SelectDispositionsView));
