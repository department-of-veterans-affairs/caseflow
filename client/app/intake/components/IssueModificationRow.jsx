import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import COPY from '../../../COPY.json';
import { FORM_TYPES } from 'app/intake/constants';
import IssueModificationList from 'app/intake/components/IssueModificationList';

const issueModificationRow = (
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
  console.log('modificationIssueRequestsObj', modificationIssueRequestsObj);
  // const modArr = Object.entries(modificationIssueRequestsObj);
  // const modKeys = Object.keys(modificationIssueRequestsObj);
  // console.log('modArr', modArr);
  // Object.entries(modificationIssueRequestsObj).map((item) => {
  //   console.log(item);
  // });

  const additionalArr =
    modificationIssueRequestsObj.Addition === null ? [] : modificationIssueRequestsObj.Addition;

  // console.log('additionalArr', additionalArr);
  const additionalSection = additionalArr?.length >= 0 ?
    <IssueModificationList
      sectionTitle="Requested Additional Issues"
      issuesArr ={additionalArr}
      lastSection={false}
    /> : null;

  const modificationIssueArr =
    modificationIssueRequestsObj.Modification === null ? [] : modificationIssueRequestsObj.Modification;

  // console.log('modificationIssueArr', modificationIssueArr);
  const modificationSection = modificationIssueArr?.length >= 0 ?
    <IssueModificationList
      sectionTitle="Requested Changes"
      issuesArr={modificationIssueArr}
      lastSection={false}
    /> : null;

  const removalIssueArr =
    modificationIssueRequestsObj.Removal === null ? [] : modificationIssueRequestsObj.Removal;

  // console.log('removalIssueArr', removalIssueArr);
  const removalSection = removalIssueArr?.length >= 0 ?
    <IssueModificationList
      sectionTitle="Requested Issue Removal"
      issuesArr={removalIssueArr}
      lastSection={false}
    /> : null;

  const withdrawalIssueArr =
    modificationIssueRequestsObj.Withdrawal === null ? [] : modificationIssueRequestsObj.Withdrawal;

  // console.log('withdrawalIssueArr', withdrawalIssueArr);
  const withdrawalSection = withdrawalIssueArr?.length >= 0 ?
    <IssueModificationList
      sectionTitle="Requested Issue Withdrawal"
      issuesArr={withdrawalIssueArr}
      lastSection
    /> : null;

  const sections = [];

  if (additionalSection !== null) {
    sections.push(additionalSection);
  }

  if (modificationSection !== null) {
    sections.push(modificationSection);
  }

  if (removalSection !== null) {
    sections.push(removalSection);
  }

  if (withdrawalSection !== null) {
    sections.push(withdrawalSection);
  }

  // console.log('sections', sections);

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

export default issueModificationRow;

issueModificationRow.propTypes = {
  editPage: PropTypes.bool,
  featureToggles: PropTypes.object,
  fieldTitle: PropTypes.string,
  formType: PropTypes.oneOf(_.map(FORM_TYPES, 'key')),
  intakeData: PropTypes.object,
  onClickIssueAction: PropTypes.func,
  sectionIssues: PropTypes.arrayOf(PropTypes.object),
  userCanWithdrawIssues: PropTypes.bool,
  withdrawIssue: PropTypes.func,
  userCanEditIntakeIssues: PropTypes.bool,
  modificationIssueRequestsObj: PropTypes.object
};
