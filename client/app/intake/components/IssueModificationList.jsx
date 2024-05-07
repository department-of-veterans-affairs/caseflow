import React from 'react';
import IssueModification from './IssueModificationRequest';

const IssueModificationList = (
  {
    sectionTitle,
    issuesArr,
    lastSection
  }
) => {
  // const addionalIssuesArr = issuesObj.Addition;
  // console.log('addionalIssuesArr', addionalIssuesArr);
  // const addionalIssuesRows = [];
  // const addionalIssueSection = addionalIssuesArr.map((issue) => {
  //   addionalIssuesRows.push(
  //     <IssueModification issue={issue} />
  //   );

  //   return addionalIssuesRows;
  // });

  // const modificationIssueArr = issuesObj.Modification;
  // console.log('modificationIssueArr', modificationIssueArr);
  // const modificationIssuesRows = [];
  // const modificationIssueSection = modificationIssueArr.map((issue) => {
  //   modificationIssuesRows.push(
  //     <IssueModification issue={issue} />
  //   );

  //   return modificationIssuesRows;
  // });

  // const removalIssueArr = issuesObj.Removal;
  // console.log('removalIssueArr', removalIssueArr);
  // const removalIssuesRows = [];
  // const removalIssuesSection = removalIssueArr.map((issue) => {
  //   removalIssuesRows.push(
  //     <IssueModification issue={issue} />
  //   );

  //   return removalIssuesRows;
  // });

  // const withdrawalIssueArr = issuesObj.Withdrawal;
  // console.log('withdrawalIssueArr', withdrawalIssueArr);
  // const withdrawalIssuesRows = [];
  // const withdrawalIssueSection = withdrawalIssueArr.map((issue) => {
  //   withdrawalIssuesRows.push(
  //     <IssueModification issue={issue} />
  //   );

  //   return withdrawalIssuesRows;
  // });

  // let issuesArr = [];

  // issuesArr = issuesArr.concat(addionalIssueSection);
  // issuesArr = issuesArr.concat(modificationIssueSection);
  // issuesArr = issuesArr.concat(removalIssuesSection);
  // issuesArr = issuesArr.concat(withdrawalIssueSection);

  const issues = issuesArr.map((issue) => {
    return <li><IssueModification issue={issue} /></li>;
  });

  return (
    <>
      <div>
        <h3>{sectionTitle}</h3>
        <ol>
          {issues}
        </ol>
      </div>
      {lastSection ? null : <hr />}
    </>
  );
};

export default IssueModificationList;
