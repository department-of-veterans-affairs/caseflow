import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import COPY from '../../../COPY';
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
  // let additionalArr = [];
  // let modificationIssueArr = [];
  // let removalIssueArr = [];
  // let withdrawalIssueArr = [];
  const sections = [];
  const modificationIssueRequestsObjKeysLength = Object.keys(modificationIssueRequestsObj).length - 1;
  // console.log('modificationIssueRequestsObjKeysLength', modificationIssueRequestsObjKeysLength);

  for (const [key, value] of Object.entries(modificationIssueRequestsObj)) {
    // console.log('key', key);
    // console.log('value', value);
    let sectionTitle;

    const lastSection =
      modificationIssueRequestsObjKeysLength === Object.keys(modificationIssueRequestsObj).indexOf(key);

    switch (key) {
    case COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.REQUEST_TYPE:
      sectionTitle = COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.SECTION_TITLE;
      break;
    case COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.REQUEST_TYPE:
      sectionTitle = COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.SECTION_TITLE;
      break;
    case COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.REQUEST_TYPE:
      sectionTitle = COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.SECTION_TITLE;
      break;
    case COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.REQUEST_TYPE:
      sectionTitle = COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.SECTION_TITLE;
      break;
    default:
      break;
    }

    sections.push(
      <IssueModificationList
        sectionTitle={sectionTitle}
        issuesArr={value}
        lastSection={lastSection}
      />
    );
  }

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
