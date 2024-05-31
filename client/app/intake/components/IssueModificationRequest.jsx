import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { formatDateStr } from 'app/util/DateUtil';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';
import Dropdown from 'app/components/SearchableDropdown';
import { capitalize } from 'lodash';

const IssueModificationRequest = ({ issueModificationRequest, userIsVhaAdmin, onClickIssueAction,  issueIndex }) => {
  const {
    benefitType,
    requestType,
    requestor,
    decisionDate,
    nonratingIssueCategory,
    nonratingIssueDescription,
    requestReason,
    requestIssue,
    withdrawalDate
  } = issueModificationRequest;

  const formattedRequestorName = `${requestor.fullName} (${requestor.cssId})`;

  const readableBenefitType = BENEFIT_TYPES[benefitType];

  const requestDetailsMapping = {
    [COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.REQUEST_TYPE]: COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.DETAILS,
    [COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.REQUEST_TYPE]: COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.DETAILS,
    [COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.REQUEST_TYPE]: COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.DETAILS,
    [COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.REQUEST_TYPE]: COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.DETAILS,
  };

  const requestDetails = requestDetailsMapping[requestType];

  let options = [];

  if (userIsVhaAdmin) {
    options.push({
      label: `Review issue ${requestType} request`,
      value: `reviewIssue${capitalize(requestType)}Request` }
    );
  }

  const requestReasonSection = (
    <>
      <h4>{requestDetails}:</h4>
      <p>{requestReason}</p>
    </>
  );

  const modificationRequestInfoSection = (
    <div>
      <p>{nonratingIssueCategory} - {nonratingIssueDescription}</p>
      <p>Benefit type: {readableBenefitType}</p>
      <p>Decision date: {formatDateStr(decisionDate)}</p>
      <br />
    </div>
  );

  const requestedByUser = (
    <div>
      <br />
      <h4>Requested by:</h4>
      <p>{formattedRequestorName}</p>
      <br />
    </div>
  );

  const requestIssueInfo = () => {
    if (!requestIssue) {
      return;
    }

    const requestIsssueDescription = requestIssue.description ||
     `${requestIssue.nonratingIssueCategory} - ${requestIssue.nonratingIssueDescription}`;

    return (
      <>
        <h3>Original Issue</h3>
        <div className="issue-modification-request-original">
          <ol>
            <li>
              <p>{requestIsssueDescription}</p>
              <p>Benefit type: {BENEFIT_TYPES[requestIssue.benefitType]}</p>
              <p>Decision date: {formatDateStr(requestIssue.decisionDate)}</p>
            </li>
          </ol>
        </div>
      </>);
  };

  const extraContentMapping = {
    [COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.REQUEST_TYPE]: (
      <>
        {requestedByUser}
        {requestIssueInfo()}
      </>
    ),
    [COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.REQUEST_TYPE]: (
      <>
        <br />
        <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.DATE}:</h4>
        <p>{formatDateStr(withdrawalDate)}</p>
        {requestedByUser}
      </>
    ),
    [COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.REQUEST_TYPE]: requestedByUser,
    [COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.REQUEST_TYPE]: requestedByUser,
  };

  const extraContent = extraContentMapping[requestType] || null;

  return (
    <>
      <div className="issue" data-key={`issue-${requestType}`} key={`issue-${requestType}`} id={`issue-${requestType}-${requestIssue.id}`}>
        <div className="issue-desc">
          {modificationRequestInfoSection}
          {requestReasonSection}
          {extraContent}
        </div>
        <div className="issue-action">
          <Dropdown
            name={`select-action-${requestType}`}
            label="Actions"
            options={options}
            placeholder="Select action"
            hideLabel
            onChange={(option) => onClickIssueAction(issueIndex, option.value)}
            doubleArrow
            searchable={false}
          />
        </div>
      </div>
    </>
  );
};

export default IssueModificationRequest;

IssueModificationRequest.propTypes = {
  issueModificationRequest: PropTypes.object
};
