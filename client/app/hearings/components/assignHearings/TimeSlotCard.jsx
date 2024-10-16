import React from 'react';
import PropTypes from 'prop-types';

import { TimeSlotDetail } from '../scheduleHearing/TimeSlotDetail';
import { HearingAppellantName } from './AssignHearingsFields';
import { HearingTime } from '../HearingTime';
import { HearingTimeScheduledInTimezone } from '../HearingTimeScheduledInTimezone';
import { Dot } from '../../../components/Dot';

export const TimeSlotCard = ({
  hearing,
  hearingDay,
  regionalOffice,
  mstIdentification,
  pactIdentification,
  legacyMstPactIdentification }) => {
  return (
    <div className="usa-grid time-slot-card">
      <div className="usa-width-one-fourth">
        {hearing.scheduledInTimezone ?
          <HearingTimeScheduledInTimezone
            primaryLabel="RO"
            hearing={hearing}
            paragraphClasses="time-slot-card-time"
            labelClasses="time-slot-card-label"
            breakCharacter=""
          /> :
          <HearingTime
            primaryLabel="RO"
            hearing={hearing}
            paragraphClasses="time-slot-card-time"
            labelClasses="time-slot-card-label"
            breakCharacter=""
          />}
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
          hearing={hearing}
          mstIdentification={mstIdentification}
          pactIdentification={pactIdentification}
          legacyMstPactIdentification={legacyMstPactIdentification}
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
  mstIdentification: PropTypes.bool,
  pactIdentification: PropTypes.bool,
  legacyMstPactIdentification: PropTypes.bool
};
