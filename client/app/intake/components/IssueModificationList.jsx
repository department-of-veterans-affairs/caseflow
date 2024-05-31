import React from 'react';
import PropTypes from 'prop-types';
import IssueModificationRequest from './IssueModificationRequest';

const IssueModificationList = (
  {
    sectionTitle,
    issueModificationRequests,
    userIsVhaAdmin,
    onClickIssueAction,
  }
) => {
  const issues = issueModificationRequests.map((issueModificationRequest, id) => {
    return (
      <li key={id}>
        <IssueModificationRequest
          issueModificationRequest={issueModificationRequest}
          userIsVhaAdmin={userIsVhaAdmin}
          onClickIssueAction={onClickIssueAction}
          issueIndex={issueModificationRequest.id}
        />
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
        <div className="issues">
          <div className="issue-container">
            <ol>
              {issues}
            </ol>
          </div>
        </div>
      </div>
    </>
  );
};

export default IssueModificationList;

IssueModificationList.propTypes = {
  sectionTitle: PropTypes.string.isRequired,
  issueModificationRequests: PropTypes.arrayOf(PropTypes.object).isRequired,
  userIsVhaAdmin: PropTypes.bool,
  onClickIssueAction: PropTypes.func,
};
