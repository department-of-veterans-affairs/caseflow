import React from 'react';
import PropTypes from 'prop-types';
import IssueModificationRequest from './IssueModificationRequest';

const IssueModificationList = (
  {
    sectionTitle,
    issueModificationRequests,
    onClickIssueAction,
  }
) => {
  const issueModificationLists = issueModificationRequests.map((issueModificationRequest, index) => {
    return (
      <li key={index}>
        <IssueModificationRequest
          issueModificationRequest={issueModificationRequest}
          onClickIssueAction={onClickIssueAction}
          IssueModificationRequestIndex={index}
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
  onClickIssueAction: PropTypes.func,
};
