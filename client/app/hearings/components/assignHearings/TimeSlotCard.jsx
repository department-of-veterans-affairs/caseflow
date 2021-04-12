import React from 'react';
import PropTypes from 'prop-types';

import { TimeSlotDetail } from '../scheduleHearing/TimeSlotDetail';
import { HearingAppellantName } from './AssignHearingsFields';
import { HearingTime } from '../HearingTime';
import { Dot } from '../../../components/Dot';

export const TimeSlotCard = ({ hearing, hearingDay, regionalOffice }) => {
  return (
    <div className="usa-grid time-slot-card">
      <div className="usa-width-one-fourth">
        <HearingTime
          primaryLabel="RO"
          hearing={hearing}
          paragraphClasses="time-slot-card-time"
          labelClasses="time-slot-card-label"
          breakCharacter=""
        />
      </div>
      <div className="usa-width-three-fourths">
        <TimeSlotDetail
          {...hearing}
          hearingDay={hearingDay}
          regionalOffice={regionalOffice}
          issueCount={hearing.currentIssueCount}
          showType
          showDetails
          itemSpacing={5}
          label={
            <span className="time-slot-card-label">
              <HearingAppellantName
                hearing={{
                  ...hearing,
                  veteranFileNumber: `Veteran ID: ${hearing.veteranFileNumber}`,
                }}
                spacingCharacter={<Dot spacing={2} />}
              />
            </span>
          }
        />
      </div>
    </div>
  );
};

TimeSlotCard.propTypes = {
  hearing: PropTypes.object,
  hearingDay: PropTypes.object,
  regionalOffice: PropTypes.string,
};
