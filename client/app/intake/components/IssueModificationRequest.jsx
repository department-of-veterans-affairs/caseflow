import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { onClickModifcationAction } from 'app/intake/util/issueModificationRequests';

const IssueModificationRequest = ({
  benefitType,
  decisionDate,
  details,
  nonRatingIssueCategory,
  nonRatingIssueDescription,
  requestor,
  requestReason,
  originalIssue,
  withDrawal,
  modificationActionOptions
}) => {
  return (
    <div className="modification-request">
      <div className="modification-request-text">
        <div>
          <p>{nonRatingIssueCategory} - {nonRatingIssueDescription}</p>
          <p>Benefit type: {benefitType}</p>
          <p>Decision date: {decisionDate}</p>
          <br />
        </div>
        <h4>{details}:</h4>
        <p>{requestReason}</p>
        {withDrawal}
        <div>
          <br />
          <h4>Requested by:</h4>
          <p>{requestor.fullName} ({requestor.cssId})</p>
          <br />
        </div>
        {originalIssue}
      </div>
      <SearchableDropdown
        name="modification-action"
        label="Actions"
        hideLabel
        searchable={false}
        options={modificationActionOptions}
        placeholder="Select action"
        onChange={(option) => onClickModifcationAction(option.value)}
      />
    </div>
  );
};

export default IssueModificationRequest;

IssueModificationRequest.propTypes = {
  benefitType: PropTypes.string.isRequired,
  decisionDate: PropTypes.string.isRequired,
  details: PropTypes.string.isRequired,
  nonRatingIssueCategory: PropTypes.string.isRequired,
  nonRatingIssueDescription: PropTypes.string.isRequired,
  requestor: PropTypes.object.isRequired,
  requestReason: PropTypes.string.isRequired,
  originalIssue: PropTypes.object,
  withDrawal: PropTypes.object,
  modificationActionOptions: PropTypes.array
};
