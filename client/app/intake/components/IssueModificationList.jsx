import React from 'react';
import PropTypes from 'prop-types';
import IssueModificationRequest from './IssueModificationRequest';
import COPY from '../../../COPY';
import { formatDateStr } from 'app/util/DateUtil';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';

const IssueModificationList = (
  {
    sectionTitle,
    issueModificationRequests,
  }
) => {
  const issues = issueModificationRequests.map((issueModificationRequest, id) => {

    return (
      <li key={id}>
        <IssueModificationRequest issueModificationRequest={issueModificationRequest modificationActionOptions={generateModificationOptions(optionsLabel)}} />
        {issueModificationRequests.length > 1 && id !== issueModificationRequests.length - 1 ?
          <>
            <hr />
            <br />
          </> : null}
      </li>
    );
  });

  return (
    <>
      <div>
        <br />
        <h3>{sectionTitle}</h3>
        <br />
        <ol>
          {issues}
        </ol>
      </div>
    </>
  );
};

export default IssueModificationList;

IssueModificationList.propTypes = {
  sectionTitle: PropTypes.string.isRequired,
  issueModificationRequests: PropTypes.arrayOf(PropTypes.object).isRequired,
};
