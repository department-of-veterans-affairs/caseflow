import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import IssueModificationList from 'app/intake/components/IssueModificationList';
import { groupBy } from 'lodash';

const issueModificationRow = (
  {
    fieldTitle,
    issueModificationRequests,
  }) => {
  const sectionTitleMapper = {
    [COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.REQUEST_TYPE]:
      COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.SECTION_TITLE,
    [COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.REQUEST_TYPE]:
      COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.SECTION_TITLE,
    [COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.REQUEST_TYPE]:
      COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.SECTION_TITLE,
    [COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.REQUEST_TYPE]:
      COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.SECTION_TITLE
  };

  // Group the modification requests by sections based on their request type e.g. addition, modification
  const groupedIssueModificationRequests = groupBy(issueModificationRequests, 'requestType');

  // Sort and map over the key value pairs to display the issue modification requests grouped by request type in the UI
  const sections = Object.entries(groupedIssueModificationRequests).sort().
    map(([key, value], i, issueRequestEntries) => {
      const lastSection = issueRequestEntries.length - 1 === i;

      return (
        <React.Fragment key={`${key}-${i}`}>
          <IssueModificationList
            issueModificationRequests={value}
            sectionTitle={sectionTitleMapper[key]}
            lastSection={lastSection}
            key={`${key}-${i}`}
          />
          {lastSection ? null : <hr />}
        </React.Fragment>
      );
    });

  return {
    content: (
      <div>
        {sections}
      </div>
    ),
    field: fieldTitle,
  };
};

export default issueModificationRow;

issueModificationRow.propTypes = {
  fieldTitle: PropTypes.string,
  issueModificationRequests: PropTypes.object
};
