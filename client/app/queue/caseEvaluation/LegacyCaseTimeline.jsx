import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { redText } from '../constants';
import { AttorneyTaskTimeline } from './AttorneyTaskTimeline';
import { AttorneyDaysWorked } from './AttorneyDaysWorked';

export const LegacyCaseTimeline = (props) => {
  const {
    appeal,
    attorneyChildrenTasks,
    aod,
    cavc,
    caseType,
    daysAssigned,
    dateAssigned,
    decisionSubmitted,
  } = props;

  return (
    <>
      <div className="case-timeline" >
        <span className="case-type">
          <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_CASE_TYPE}</b>:
          { aod && <span {...redText}> AOD</span> }
          { cavc && <span {...redText}> CAVC</span> }
          { !aod && !cavc && <span> {caseType}</span> }
        </span>
        <AttorneyDaysWorked
          attorneyTasks={attorneyChildrenTasks}
          daysAssigned={daysAssigned}
          isLegacy />
      </div>
      <br />
      <span>{dateAssigned.format('M/D/YY')} - {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_ASSIGNED_DATE}</span>
      <AttorneyTaskTimeline title="Attorney Task Timeline"
        appeal={appeal}
        attorneyChildrenTasks={attorneyChildrenTasks} />
      <span>
        {decisionSubmitted.format('M/D/YY')} - {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_SUBMITTED_DATE}
      </span>
    </>
  );
};

LegacyCaseTimeline.propTypes = {
  appeal: PropTypes.object,
  attorneyChildrenTasks: PropTypes.array,
  aod: PropTypes.bool,
  cavc: PropTypes.bool,
  caseType: PropTypes.string,
  daysAssigned: PropTypes.number,
  dateAssigned: PropTypes.object,
  decisionSubmitted: PropTypes.object,
};
