import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import COPY from '../../../COPY';
import { FORM_TYPES } from 'app/intake/constants';
import IssueModificationList from 'app/intake/components/IssueModificationList';

const issueModificationRow = (
  {
    fieldTitle,
    modificationIssueRequestsObj
  }) => {
  const sections = [];
  const modificationIssueRequestsObjKeysLength = Object.keys(modificationIssueRequestsObj).length - 1;
  const modificationIssueRequestsArr = Object.entries(modificationIssueRequestsObj).sort();

  let index = 0;

  for (const [key, value] of modificationIssueRequestsArr) {
    const lastSection =
      modificationIssueRequestsObjKeysLength === index;

    const commonProps = {
      issuesArr: value,
      lastSection
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

    index += 1;
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
  editPage: PropTypes.bool,
  featureToggles: PropTypes.object,
  fieldTitle: PropTypes.string,
  formType: PropTypes.oneOf(_.map(FORM_TYPES, 'key')),
  intakeData: PropTypes.object,
  onClickIssueAction: PropTypes.func,
  sectionIssues: PropTypes.arrayOf(PropTypes.object),
  userCanWithdrawIssues: PropTypes.bool,
  withdrawIssue: PropTypes.func,
  userCanEditIntakeIssues: PropTypes.bool,
  modificationIssueRequestsObj: PropTypes.object
};
