import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
// import COPY from '../../../../../COPY';
import { FORM_TYPES } from 'app/intake/constants';
import IssueModification from 'app/intake/components/IssueModification';

const issueSectionRow = (
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
  // const reviewHasPredocketVhaIssues = sectionIssues.some(
  //   (issue) => issue.benefitType === 'vha' && issue.isPreDocketNeeded === 'true'
  // );
  // const showPreDocketBanner = !editPage && formType === 'appeal' && reviewHasPredocketVhaIssues;

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
        <IssueModification
          modificationIssueRequestsObj
        />
      </div>
    ),
    field: fieldTitle,
  };
};

export default issueSectionRow;

issueSectionRow.propTypes = {
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
