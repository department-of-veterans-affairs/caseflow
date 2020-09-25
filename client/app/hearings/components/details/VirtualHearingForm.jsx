import PropTypes from 'prop-types';
import React, { useContext, useEffect } from 'react';

import { ContentSection } from '../../../components/ContentSection';
import { HearingLinks } from './HearingLinks';
import { HearingsUserContext } from '../../contexts/HearingsUserContext';
import { getAppellantTitle } from '../../utils';
import { VirtualHearingFields } from '../VirtualHearings/Fields';

export const VirtualHearingForm = (
  { hearing, initialHearing, virtualHearing, readOnly, update, errors }
) => {
  if (!hearing?.isVirtual && !hearing?.wasVirtual) {
    return null;
  }

  // Hide the virtual hearing fields only when we are scheduling the virtual hearing
  const showFields = (hearing?.isVirtual || hearing?.wasVirtual) && virtualHearing;
  const readOnlyEmails = readOnly || !virtualHearing?.jobCompleted || hearing?.wasVirtual || hearing.scheduledForIsPast;
  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);
  const user = useContext(HearingsUserContext);

  useEffect(() => {
    // Try to use the existing timezones if present
    const { appellantTz, representativeTz } = (virtualHearing || {});

    // Set the  timezone if not already set
    update('virtualHearing', {
      [!representativeTz && 'representativeTz']: representativeTz,
      [!appellantTz && 'appellantTz']: appellantTz,
    });
  }, []);

  return (
    <ContentSection
      header={`${hearing?.wasVirtual ? 'Previous ' : ''}Virtual Hearing Details`}
    >
      <HearingLinks
        user={user}
        hearing={hearing}
        virtualHearing={virtualHearing}
        isVirtual={hearing?.isVirtual}
        wasVirtual={hearing?.wasVirtual}
      />
      <div className="cf-help-divider" />
      {showFields && (
        <VirtualHearingFields
          appellantTitle={appellantTitle}
          errors={errors}
          readOnly={readOnlyEmails}
          update={update}
          virtualHearing={virtualHearing}
          time={hearing.scheduledTimeString}
          requestType={hearing.readableRequestType}
          initialRepresentativeTz={initialHearing?.virtualHearing?.representativeTz}
        />
      )}
    </ContentSection>
  );
};

VirtualHearingForm.propTypes = {
  update: PropTypes.func,
  hearing: PropTypes.shape({
    readableRequestType: PropTypes.string,
    scheduledTimeString: PropTypes.string,
    appellantIsNotVeteran: PropTypes.bool,
    scheduledForIsPast: PropTypes.bool,
    wasVirtual: PropTypes.bool,
    isVirtual: PropTypes.bool
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
