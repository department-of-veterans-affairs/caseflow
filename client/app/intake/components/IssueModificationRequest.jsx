import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { formatDateStr } from 'app/util/DateUtil';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';

const IssueModificationRequest = ({ issueModificationRequest }) => {
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

    return <>
      <div>
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
      </div>
      <br />
    </>;
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
    <div>
      {modificationRequestInfoSection}
      {requestReasonSection}
      {extraContent}
    </div>
  );
};

export default IssueModificationRequest;

IssueModificationRequest.propTypes = {
  issueModificationRequest: PropTypes.object
};
