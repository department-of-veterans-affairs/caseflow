import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import IssueModificationList from 'app/intake/components/IssueModificationList';

const issueModificationRow = (
  {
    fieldTitle,
    modificationIssueRequestsObj,
    issueModificationRequests,
    onClickPendingIssueAction
  }) => {
  const sections = [];
  const modificationIssueRequestsLength = Object.keys(modificationIssueRequestsObj).length - 1;
  const modificationIssueRequests = Object.entries(modificationIssueRequestsObj).sort();

  for (const [i, [key, value]] of modificationIssueRequests.entries()) {
    const lastSection =
      modificationIssueRequestsLength === i;

    const commonProps = {
      issuesArr: value,
      lastSection,
      issueModificationRequests,
      onClickPendingIssueAction
    };

    switch (key) {
    case COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.REQUEST_TYPE:
      sections.push(
        <IssueModificationList
          sectionTitle={COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.SECTION_TITLE}
          {...commonProps}
        />
      );
      break;
    case COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.REQUEST_TYPE:
      sections.push(
        <IssueModificationList
          sectionTitle={COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.SECTION_TITLE}
          {...commonProps}
        />
      );
      break;
    case COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.REQUEST_TYPE:
      sections.push(
        <IssueModificationList
          sectionTitle={COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.SECTION_TITLE}
          {...commonProps}
        />
      );
      break;
    case COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.REQUEST_TYPE:
      sections.push(
        <IssueModificationList
          sectionTitle={COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.SECTION_TITLE}
          {...commonProps}
        />
      );
      break;
    default:
      break;
    }
  }

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
  modificationIssueRequestsObj: PropTypes.object
};
