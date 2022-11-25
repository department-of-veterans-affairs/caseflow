import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { calculateDaysWorked } from './calculateDaysWorked';

export const AttorneyDaysWorked = ({ attorneyTasks, daysAssigned, isLegacy }) => {
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
  isLegacy: PropTypes.bool
};
