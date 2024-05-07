import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
// import COPY from '../../../../../COPY';
import { FORM_TYPES } from 'app/intake/constants';
import IssueModificationList from 'app/intake/components/IssueModificationList';

const issueModificationSectionRow = (
  {
    // editPage,
    // featureToggles,
    fieldTitle,
    // formType,
    // intakeData,
    // onClickIssueAction,
    // sectionIssues,
    // userCanWithdrawIssues,
    // userCanEditIntakeIssues,
    // withdrawReview
    modificationIssueRequestsObj
  }) => {
  // console.log('in IssueModificationRow', modificationIssueRequestsObj);

  const sections = [];
  const addionalIssuesArr = modificationIssueRequestsObj.Addition;
  // console.log('addionalIssuesArr', addionalIssuesArr);
  const addionalSection =
    <IssueModificationList sectionTitle="Requested Additional Issues" issuesArr ={addionalIssuesArr} lastSection={false} />;

  sections.push(addionalSection);

  const modificationIssueArr = modificationIssueRequestsObj.Modification;
  // console.log('modificationIssueArr', modificationIssueArr);
  const modificationSection =
    <IssueModificationList sectionTitle="Requested Changes" issuesArr ={modificationIssueArr} lastSection={false} />;

  sections.push(modificationSection);

  const removalIssueArr = modificationIssueRequestsObj.Removal;
  // console.log('removalIssueArr', removalIssueArr);
  const removalSection =
    <IssueModificationList sectionTitle="Requested Issue Removal" issuesArr ={removalIssueArr} lastSection={false} />;

  sections.push(removalSection);

  const withdrawalIssueArr = modificationIssueRequestsObj.Withdrawal;
  // console.log('withdrawalIssueArr', withdrawalIssueArr);
  const withdrawalSection =
    <IssueModificationList sectionTitle="Requested Issue Withdrawal" issuesArr ={withdrawalIssueArr} lastSection />;

  sections.push(withdrawalSection);

  return {
    content: (
      <div>
        {/* {intakeData.editEpUpdateError && (
          <ErrorAlert errorCode="unable_to_edit_ep" />
        )} */}
        {/* { !fieldTitle.includes('issues') && <span><strong>Additional </strong></span> } */}
        {/* <IssueList
          editPage={editPage}
          intakeData={intakeData}
          issues={sectionIssues}
          featureToggles={featureToggles}
          formType={formType}
          onClickIssueAction={onClickIssueAction}
          userCanWithdrawIssues={userCanWithdrawIssues}
          withdrawReview={withdrawReview}
          userCanEditIntakeIssues={userCanEditIntakeIssues}
        /> */}
        {/*  {showPreDocketBanner && <Alert message={COPY.VHA_PRE_DOCKET_ADD_ISSUES_NOTICE} type="info" />} */}

        {/* <IssueModificationList
          issuesObj={modificationIssueRequestsObj}
        /> */}
        {sections}
      </div>
    ),
    field: fieldTitle,
  };
};

export default issueModificationSectionRow;

issueModificationSectionRow.propTypes = {
  editPage: PropTypes.bool,
  featureToggles: PropTypes.object,
  fieldTitle: PropTypes.string,
  formType: PropTypes.oneOf(_.map(FORM_TYPES, 'key')),
  intakeData: PropTypes.object,
  onClickIssueAction: PropTypes.func,
  sectionIssues: PropTypes.arrayOf(PropTypes.object),
  userCanWithdrawIssues: PropTypes.bool,
  withdrawIssue: PropTypes.func,
  userCanEditIntakeIssues: PropTypes.bool
};
