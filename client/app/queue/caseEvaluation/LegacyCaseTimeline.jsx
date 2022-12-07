import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { AttorneyTaskTimeline } from './AttorneyTaskTimeline';
import { AttorneyDaysWorked } from './AttorneyDaysWorked';
import { sortCaseTimelineEvents } from '../utils';

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

  const notWithAttorneyLocations = appeal.locationHistory.filter((location) => !location.withAttorney);
  const tasks = sortCaseTimelineEvents([...attorneyChildrenTasks, ...notWithAttorneyLocations]);

  return (
    <>
      <div className="case-timeline" >
        <AttorneyDaysWorked
          attorneyTasks={tasks}
          daysAssigned={daysAssigned}
          aod={aod}
          cavc={cavc}
          caseType={caseType}
          isLegacy />
      </div>
      <br />
      <span>{dateAssigned.format('M/D/YY')} - {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_ASSIGNED_DATE}</span>
      <AttorneyTaskTimeline title="Attorney Task Timeline"
        appeal={appeal}
        attorneyChildrenTasks={tasks} />
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
