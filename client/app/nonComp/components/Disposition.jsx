import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import update from 'immutability-helper';
import moment from 'moment';
import { css } from 'glamor';

import { formatDateStr, formatDateStrUtc } from '../../util/DateUtil';
import InlineForm from '../../components/InlineForm';
import DateSelector from '../../components/DateSelector';
import Button from '../../components/Button';
import COPY from '../../../COPY';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';

import PowerOfAttorneyDecisionReview from './PowerOfAttorneyDecisionReview';

import { DISPOSITION_OPTIONS, DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import {
  formatDecisionIssuesFromRequestIssues,
  formatRequestIssuesWithDecisionIssues,
  buildDispositionSubmission
} from '../util';
import Link from 'app/components/Link';
import Alert from '../../components/Alert';
import { sprintf } from 'sprintf-js';

const messageStyling = css({
  fontSize: '17px !important',
});

class NonCompDecisionIssue extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      issueIdx: props.index
    };
  }

  handleDispositionChange = (option) => {
    this.props.onDispositionChange(this.state.issueIdx, option && option.value);
  }

  dispositionOptions = () => {
    const isSupplementalClaim = this.props.issue.decision_review_title === 'Supplemental Claim';

    return DISPOSITION_OPTIONS.filter((code) => {
      return !isSupplementalClaim || code !== 'DTA Error';
    }).map((code) => {
      return {
        value: code,
        label: code
      };
    });
  }

  handleDescriptionChange = (value) => {
    this.props.onDescriptionChange(this.state.issueIdx, value);
  }

  render = () => {
    const {
      issue,
      index,
      disabled
    } = this.props;
    let issueDate = formatDateStr(issue.approx_decision_date);

    return <div className="cf-decision">
      <hr />
      <div className="usa-grid-full">
        <h3>Issue #{index + 1}</h3>
        <div className="cf-decision-details">
          <div className="desc">{issue.description}</div>
          <div className="date"><strong>Prior decision date:</strong> {issueDate}.</div>
        </div>
        <div className="cf-disposition">
          <strong>Disposition</strong>
          <SearchableDropdown
            readOnly={disabled}
            name={`disposition-issue-${index}`}
            label={`disposition-issue-${index}`}
            hideLabel
            placeholder="Select or enter..."
            options={this.dispositionOptions()}
            value={this.props.decisionDisposition}
            onChange={this.handleDispositionChange} />
        </div>
        <div className="cf-disposition">
          <div><strong>Decision description</strong><span className="cf-optional">Optional</span></div>
          <TextareaField name={`description-issue-${index}`}
            label={`description-issue-${index}`}
            hideLabel
            value={this.props.decisionDescription || ''}
            disabled={disabled}
            onChange={this.handleDescriptionChange} />
        </div>

      </div>
    </div>;
  }
}

class NonCompDispositions extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      requestIssues: formatRequestIssuesWithDecisionIssues(
        this.props.task.appeal.activeOrDecidedRequestIssues, this.props.appeal.decisionIssues),
      decisionDate: '',
      isFilledOut: false,
      errorMessage: ''
    };
  }

  handleDecisionDate = (value) => {
    this.setState({ decisionDate: value }, this.checkFormFilledOut);
  }

  handleSave = () => {
    const decisionIssues = formatDecisionIssuesFromRequestIssues(this.state.requestIssues);
    const dispositionData = buildDispositionSubmission(decisionIssues, this.state.decisionDate);

    this.props.handleSave(dispositionData);
  }

  validateDecisionDate = () => {
    const decisionDate = formatDateStr(this.state.decisionDate);
    const receiptDate = formatDateStr(this.props.appeal.receiptDate);

    const dateIsValid = Boolean((new Date(decisionDate)) >= new Date(receiptDate)) &&
      Boolean(Date.parse(decisionDate) < new Date());

    if (dateIsValid) {
      this.setState({ errorMessage: '' });
    } else {
      this.setState({
        errorMessage: sprintf(
          COPY.DATE_SELECTOR_DATE_RANGE_ERROR,
          formatDateStr(this.props.appeal.receiptDate),
          formatDateStr(new Date())),
        isFilledOut: false
      });
    }

    return dateIsValid;
  }

  checkFormFilledOut = () => {
    // check if all dispositions have values & date is set
    const allDispositionsSet = this.state.requestIssues.every(
      (requestIssue) => Boolean(requestIssue.decisionIssue.disposition));

    let validDate = null;

    if (this.state.decisionDate) {
      validDate = this.validateDecisionDate();
    }

    this.setState({ isFilledOut: (allDispositionsSet && validDate) });
  }

  onDecisionIssueDispositionChange = (requestIssueIndex, value) => {
    const newRequestIssues = update(this.state.requestIssues,
      { [requestIssueIndex]: { decisionIssue: { disposition: { $set: value } } } });

    this.setState({ requestIssues: newRequestIssues }, this.checkFormFilledOut);
  }

  onDecisionIssueDescriptionChange = (requestIssueIndex, value) => {
    const newRequestIssues = update(this.state.requestIssues,
      { [requestIssueIndex]: { decisionIssue: { description: { $set: value } } } });

    this.setState({ requestIssues: newRequestIssues });
  }

  establishmentCreditsTimestamp() {
    const tstamp = moment(this.props.task.created_at).format('ddd MMM DD YYYY [at] HH:mm');

    if (this.props.task.tasks_url) {
      return tstamp;
    }
  }

  establishmentCredits() {
    return <div className="cf-push-left">
      <span> Form created by: {this.props.appeal.intakeUser} on {this.establishmentCreditsTimestamp()} </span>
    </div>;
  }

  render = () => {
    const {
      appeal,
      decisionIssuesStatus,
      isBusinessLineAdmin,
      task
    } = this.props;

    let completeDiv = null;

    let decisionDate = this.state.decisionDate;

    if (appeal.decisionIssues.length > 0) {
      decisionDate = formatDateStrUtc(appeal.decisionIssues[0].approxDecisionDate, 'YYYY-MM-DD');
    }

    let editIssuesLink = null;
    const editIssuesDisabled = task.type === 'Remand';
    const editIssuesButtonType = editIssuesDisabled ? 'disabled' : 'secondary';
    const displayPOAComponent = task.business_line === 'vha';
    const displayRequestIssueModification = (!displayPOAComponent || isBusinessLineAdmin);

    const decisionHasPendingRequestIssues = task.pending_issue_modification_count > 0;
    const receiptDate = formatDateStrUtc(appeal.receiptDate, 'YYYY-MM-DD');

    if (!task.closed_at) {
      completeDiv = <React.Fragment>
        <div className="cf-txt-r">
          <a className="cf-cancel-link" href={`${task.tasks_url}`}>Cancel</a>
          <Button className="usa-button"
            name="submit-update"
            loading={decisionIssuesStatus.update === DECISION_ISSUE_UPDATE_STATUS.IN_PROGRESS}
            disabled={!this.state.isFilledOut} onClick={this.handleSave}>Complete</Button>
        </div>
      </React.Fragment>;

      editIssuesLink = (displayRequestIssueModification) ? <React.Fragment>
        <Link
          button={editIssuesButtonType}
          href={appeal.editIssuesUrl}>
          Edit Issues
        </Link>
      </React.Fragment> : <React.Fragment>
        <Link
          button={editIssuesButtonType}
          href={appeal.editIssuesUrl}>
          Request issue modification
        </Link>
        <Button disabled>Edit Issues</Button>
      </React.Fragment>;
    }

    const decisionHeaderText = displayRequestIssueModification ? COPY.DISPOSITION_DECISION_HEADER_ADMIN :
      COPY.DISPOSITION_DECISION_HEADER_NONADMIN;

    const bannerDecisionBannerText = (decisionHasPendingRequestIssues && isBusinessLineAdmin) ?
      COPY.VHA_BANNER_DISPOSITIONS_CANNOT_BE_UPDATED_ADMIN :
      COPY.VHA_BANNER_DISPOSITIONS_CANNOT_BE_UPDATED_NON_ADMIN;

    const disableIssueFields = Boolean(task.closed_at) || decisionHasPendingRequestIssues;

    return <div>
      {displayPOAComponent && <div className="cf-decisions">
        <div className="cf-decision">
          <hr />
          <div className="usa-grid-full">
            <h2>{COPY.CASE_DETAILS_POA_SUBSTITUTE} </h2>
            <PowerOfAttorneyDecisionReview
              appealId={task.appeal.uuid}
            />
          </div>
        </div>
      </div>}
      <div className="cf-decisions">
        <div className="cf-decision">
          {displayPOAComponent && <hr />}
          <div className="usa-grid-full">
            <div className="usa-width-one-half">
              <h2 style={{ marginBottom: '30px' }}>Decision</h2>
            </div>
            <div className="usa-width-one-half cf-txt-r">
              {editIssuesLink}
            </div>
          </div>
          <div className="usa-grid-full">
            {isBusinessLineAdmin && decisionHasPendingRequestIssues ? null :
              <div className="usa-width-one-whole" style={{ paddingBottom: '30px' }} >{decisionHeaderText}</div>
            }
            {editIssuesDisabled ?
              <div className="usa-width-one-whole">

                <Alert type="info" messageStyling={messageStyling} message={COPY.REMANDS_NOT_EDITABLE} />
              </div> : null}
            {decisionHasPendingRequestIssues ?
              <div className="usa-width-one-whole">
                <Alert type="info" messageStyling={messageStyling} message={bannerDecisionBannerText} />
              </div> :
              null}
          </div>
        </div>
        <div className="cf-decision-list">
          {
            this.state.requestIssues.map((issue, index) => {
              return <NonCompDecisionIssue key={`issue-${index}`} issue={issue} index={index}
                onDispositionChange={this.onDecisionIssueDispositionChange}
                onDescriptionChange={this.onDecisionIssueDescriptionChange}
                decisionDescription={issue.decisionIssue.description}
                decisionDisposition={issue.decisionIssue.disposition}
                disabled={disableIssueFields}
              />;
            })
          }
        </div>
      </div>
      <div className="cf-gray-box">
        <div className="cf-decision-date">
          <InlineForm>
            <DateSelector
              label={COPY.DISPOSITION_DECISION_DATE_LABEL}
              name="decision-date"
              value={decisionDate}
              onChange={this.handleDecisionDate}
              readOnly={disableIssueFields}
              minDate={receiptDate}
              errorMessage={this.state.errorMessage}
              noFutureDates
              type="date"
            />
          </InlineForm>
        </div>
      </div>
      {completeDiv}
      {this.establishmentCredits()}
    </div>;
  }
}

NonCompDecisionIssue.propTypes = {
  issue: PropTypes.object,
  index: PropTypes.number,
  onDispositionChange: PropTypes.func,
  onDescriptionChange: PropTypes.func,
  decisionDescription: PropTypes.string,
  decisionDisposition: PropTypes.string,
  disabled: PropTypes.bool
};

NonCompDispositions.propTypes = {
  task: PropTypes.object,
  appeal: PropTypes.object,
  decisionIssuesStatus: PropTypes.object,
  isBusinessLineAdmin: PropTypes.bool,
  handleSave: PropTypes.func
};

export default connect(
  (state) => ({
    appeal: state.nonComp.appeal,
    task: state.nonComp.task,
    decisionIssuesStatus: state.nonComp.decisionIssuesStatus,
    isBusinessLineAdmin: state.nonComp.isBusinessLineAdmin
  })
)(NonCompDispositions);
