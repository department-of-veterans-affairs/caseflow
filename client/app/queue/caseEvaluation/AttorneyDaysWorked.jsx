import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { calculateDaysWorked } from './calculateDaysWorked';
import { redText } from '../constants';

export const AttorneyDaysWorked = (props) => {
  const {
    attorneyTasks,
    daysAssigned,
    aod,
    cavc,
    caseType,
    isLegacy
  } = props;
  const allChildrenTasks = [];
  const justAttorneyTasks = [];

  if (isLegacy) {
    allChildrenTasks.push(...attorneyTasks);
  } else {
    attorneyTasks.forEach((attorneyTaskTree) => {
      justAttorneyTasks.push(attorneyTaskTree.attorneyTask);
      allChildrenTasks.push(...attorneyTaskTree.childrenTasks);
    });
  }

  const daysWorkedUpdated = calculateDaysWorked(allChildrenTasks, daysAssigned, justAttorneyTasks);

  return (
    <React.Fragment>
      <span className="case-type">
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_CASE_TYPE}</b>:
        { aod && <span {...redText}> AOD</span> }
        { cavc && <span {...redText}> CAVC</span> }
        { !aod && !cavc && <span> {caseType}</span> }
      </span>
      <span className="attorney-assigned">
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_TOTAL_DAYS_ATTORNEY_ASSIGNED}</b>: {daysAssigned}
      </span>
      <span>
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED}</b>: {daysWorkedUpdated}
      </span>
    </React.Fragment>
  );
};

AttorneyDaysWorked.propTypes = {
  daysAssigned: PropTypes.number,
  attorneyTasks: PropTypes.array,
  aod: PropTypes.bool,
  cavc: PropTypes.bool,
  caseType: PropTypes.string,
  isLegacy: PropTypes.bool
};
