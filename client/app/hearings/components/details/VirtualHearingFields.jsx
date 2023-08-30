import PropTypes from 'prop-types';
import React, { useContext } from 'react';
import { css } from 'glamor';

import { ContentSection } from '../../../components/ContentSection';
import { HearingLinks } from './HearingLinks';
import { HearingsUserContext } from '../../contexts/HearingsUserContext';

export const VirtualHearingFields = (
  { hearing, virtualHearing }
) => {
  if (!hearing?.isVirtual && !hearing?.wasVirtual) {
    return null;
  }

  const user = useContext(HearingsUserContext);
  const meetingType = hearing.judge.meetingType;
  const formattedMeetingType = meetingType.charAt(0).toUpperCase() + meetingType.slice(1);

  return (
    <ContentSection
      header={`${hearing?.wasVirtual ? 'Previous ' : ''}Virtual Hearing Links`}
    >
      <div {...css({ marginTop: '1.5rem' })}>
        <strong>{formattedMeetingType} Conference</strong>
      </div>
      <HearingLinks
        user={user}
        hearing={hearing}
        virtualHearing={virtualHearing}
        isVirtual={hearing?.isVirtual}
        wasVirtual={hearing?.wasVirtual}
      />
    </ContentSection>
  );
};

VirtualHearingFields.propTypes = {
  update: PropTypes.func,
  hearing: PropTypes.shape({
    readableRequestType: PropTypes.string,
    scheduledTimeString: PropTypes.string,
    appellantIsNotVeteran: PropTypes.bool,
    scheduledForIsPast: PropTypes.bool,
    wasVirtual: PropTypes.bool,
    isVirtual: PropTypes.bool,
    judge: PropTypes.shape({
      meetingType: PropTypes.string
    })
  }),
  initialHearing: PropTypes.shape({
    virtualHearing: PropTypes.object
  }),
  readOnly: PropTypes.bool,
  virtualHearing: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string,
    jobCompleted: PropTypes.bool
  }),
  errors: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string
  })
};
