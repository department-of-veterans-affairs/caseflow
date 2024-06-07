import React from 'react';
import PropTypes from 'prop-types';
import IssueModificationRequest from './IssueModificationRequest';

const IssueModificationList = (
  {
    sectionTitle,
    issueModificationRequests,
    onClickIssueRequestModificationAction,
  }
) => {
  const issueModificationLists = issueModificationRequests.map((issueModificationRequest, index) => {
    return (
      <li key={index}>
        <IssueModificationRequest
          issueModificationRequest={issueModificationRequest}
          onClickIssueRequestModificationAction={onClickIssueRequestModificationAction}
        />
        {issueModificationRequests.length > 1 && index !== issueModificationRequests.length - 1 ?
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
        <div className="issue-modifications">
          <div className="issue-container">
            <ol>
              {issueModificationLists}
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
  onClickIssueRequestModificationAction: PropTypes.func.isRequired
};
