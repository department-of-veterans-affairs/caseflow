import React from 'react';
import PropTypes from 'prop-types';
import IssueModificationRequest from './IssueModificationRequest';
import DropdownButton from '../../components/DropdownButton';

const IssueModificationList = (
  {
    sectionTitle,
    issueModificationRequests,
    allPendingIssues,
    onClickPendingIssueAction
  }
) => {
  console.log(issueModificationRequests)
  const issues = issueModificationRequests.map((issueModificationRequest, id) => {
    // Get index of the entire issueModificationRequests array to prepare for removal
    const index = allPendingIssues.findIndex((request) => request === issueModificationRequest);

    return (
      <li key={id}>
        <IssueModificationRequest issueModificationRequest={issueModificationRequest} />
        {issueModificationRequests.length > 1 && id !== issueModificationRequests.length - 1 ?
          <>
            <hr />
            <br />
          </> : null}

        {/* This is just temporary so that I can display the Modal during BA/UX review. */}
        <DropdownButton
          lists={
            [{ value: {
              type: 'remove', index
            },
            title: 'Remove'
            }]
          }
          onClick={(option) => onClickPendingIssueAction(option)}
        />
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
  onClickPendingIssueAction: PropTypes.func
};
