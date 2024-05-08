import React from 'react';
import PropTypes from 'prop-types';
import IssueModification from './IssueModificationRequest';

const IssueModificationList = (
  {
    sectionTitle,
    issuesArr,
    lastSection
  }
) => {
  const issues = issuesArr.map((issue) => {
    return <li key={issue.id}><IssueModification issue={issue} /></li>;
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
  issuesArr: PropTypes.arrayOf(PropTypes.object).isRequired,
  lastSection: PropTypes.bool.isRequired
};
