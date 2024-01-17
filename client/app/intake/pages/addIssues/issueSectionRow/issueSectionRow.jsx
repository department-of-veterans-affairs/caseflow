import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import COPY from '../../../../../COPY';
import { FORM_TYPES } from 'app/intake/constants';
import Alert from 'app/components/Alert';
import ErrorAlert from 'app/intake/components/ErrorAlert';
import IssueList from 'app/intake/components/IssueList';

const issueSectionRow = (
  {
    editPage,
    featureToggles,
    fieldTitle,
    formType,
    intakeData,
    onClickIssueAction,
    sectionIssues,
    userCanWithdrawIssues,
    withdrawReview
  }) => {
  const reviewHasPredocketVhaIssues = sectionIssues.some(
    (issue) => issue.benefitType === 'vha' && issue.isPreDocketNeeded === 'true'
  );
  const showPreDocketBanner = !editPage && formType === 'appeal' && reviewHasPredocketVhaIssues;

  return {
    content: (
      <div>
        {intakeData.editEpUpdateError && (
          <ErrorAlert errorCode="unable_to_edit_ep" />
        )}
        { !fieldTitle.includes('issues') && <span><strong>Requested issues</strong></span> }
        <IssueList
          editPage={editPage}
          intakeData={intakeData}
          issues={sectionIssues}
          featureToggles={featureToggles}
          formType={formType}
          onClickIssueAction={onClickIssueAction}
          userCanWithdrawIssues={userCanWithdrawIssues}
          withdrawReview={withdrawReview}
        />
        {showPreDocketBanner && <Alert message={COPY.VHA_PRE_DOCKET_ADD_ISSUES_NOTICE} type="info" />}
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
};
