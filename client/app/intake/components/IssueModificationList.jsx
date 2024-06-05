import React from 'react';
import PropTypes from 'prop-types';
import IssueModificationRequest from './IssueModificationRequest';

const IssueModificationList = (
  {
    sectionTitle,
    issueModificationRequests,
    currentUserCssId,
    onClickAction
  }
) => {

  const issues = issueModificationRequests.map((issueModificationRequest, id) => {

    return (
      <li key={id}>
        <IssueModificationRequest
          issueModificationRequest={issueModificationRequest}
          currentUserCssId={currentUserCssId}
          onClickAction={onClickAction}
          modificationRequestIndex={id}
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
