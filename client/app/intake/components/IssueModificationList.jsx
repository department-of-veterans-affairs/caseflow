import React from 'react';
import PropTypes from 'prop-types';
import IssueModificationRequest from './IssueModificationRequest';
import DropdownButton from '../../components/DropdownButton';

const IssueModificationList = (
  {
    sectionTitle,
    issuesArr,
    lastSection,
    issueModificationRequests,
    onClickPendingIssueAction,
  }
) => {
  const issues = issuesArr.map((issue, id) => {
    // Get index of the entire issueModificationRequests array to prepare for removal
    const index = issueModificationRequests.findIndex((request) => request === issue);

    return (
      <li key={id}>
        <IssueModificationRequest issue={issue} />
        {issuesArr.length > 1 && id !== issuesArr.length - 1 ?
          <>
            <hr />
            <br />
          </> : null}

        {/* This is just temporary so that I can display the Modal during BA/UX review. */}
        <DropdownButton
          lists={
            [{ value: {
              type: 'remove', index,
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
      {lastSection ? null : <hr />}
    </>
  );
};

export default IssueModificationList;

IssueModificationList.propTypes = {
  sectionTitle: PropTypes.string.isRequired,
  issueModificationRequests: PropTypes.arrayOf(PropTypes.object).isRequired,
  onClickPendingIssueAction: PropTypes.func
};
