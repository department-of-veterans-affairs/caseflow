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
import {
  highlightInvalidFormItems,
  hideSuccessMessage
} from './uiReducer/uiActions';
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
const smallTopMargin = css({ marginTop: '1rem' });

class SelectDispositionsView extends React.Component {
  getBreadcrumb = () => ({
    breadcrumb: 'Select Dispositions',
    path: `/tasks/${this.props.vacolsId}/dispositions`
  });

  getNextStepUrl = () => {
    const {
      vacolsId,
      nextStep,
      appeal: {
        attributes: { issues }
      }
    } = this.props;

    return _.map(issues, 'disposition').includes('Remanded') ?
      `/tasks/${vacolsId}/remands` : nextStep;
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

  getFooterButtons = () => {
    const {
      appeal: {
        attributes: {
          veteran_full_name: vetName,
          vbms_id: vbmsId,
          issues
        }
      }
    } = this.props;

    const nextStepText = _.map(issues, 'disposition').includes('Remanded') ?
      'Select remand reasons' : 'Finish dispositions';

    return [{
      displayText: `Go back to ${vetName} (${vbmsId})`
    }, {
      displayText: nextStepText,
      id: 'finish-dispositions'
    }];
  };

  getKeyForRow = (rowNumber) => rowNumber;
  getColumns = () => [{
    header: 'Issues',
    valueFunction: (issue, idx) => <IssueList
      appeal={{ issues: [issue] }}
      idxToDisplay={idx + 1}
      showDisposition={false} />
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

  render = () => {
    const {
      saveResult,
      vacolsId,
      appeal: { attributes: { issues } }
    } = this.props;

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
        rowObjects={issues}
        getKeyForRow={this.getKeyForRow}
        styling={tableStyling}
        bodyStyling={tbodyStyling}
      />
      <div {...marginLeft(1.5)}>
        <Link to={`/tasks/${vacolsId}/dispositions/add`}>Add Issue</Link>
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
  appeal: state.queue.pendingChanges.appeals[ownProps.vacolsId],
  saveResult: state.ui.messages.success
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateEditingAppealIssue,
  highlightInvalidFormItems,
  setDecisionOptions,
  startEditingAppealIssue,
  saveEditedAppealIssue,
  hideSuccessMessage
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SelectDispositionsView));
