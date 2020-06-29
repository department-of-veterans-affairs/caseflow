import PropTypes from 'prop-types';
import React, { useContext } from 'react';
import classnames from 'classnames';

import { ContentSection } from '../../../components/ContentSection';
import { HearingLinks } from './HearingLinks';
import { HearingsUserContext } from '../../contexts/HearingsUserContext';
import { enablePadding, maxWidthFormInput, rowThirds } from './style';
import { getAppellantTitleForHearing } from '../../utils';
import TextField from '../../../components/TextField';

export const VirtualHearingForm = (
  { hearing, virtualHearing, readOnly, update, errors }
) => {
  if (!hearing?.isVirtual && !hearing?.wasVirtual) {
    return null;
  }

  const showEmailFields = (hearing?.isVirtual || hearing?.wasVirtual) && virtualHearing;
  const readOnlyEmails = readOnly || !virtualHearing?.jobCompleted || hearing?.wasVirtual || hearing.scheduledForIsPast;
  const appellantTitle = getAppellantTitleForHearing(hearing);
  const user = useContext(HearingsUserContext);

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
      {showEmailFields && (
        <React.Fragment>
          <div id="email-section" className="cf-help-divider" />
          <h3>{appellantTitle}</h3>
          <div {...rowThirds}>
            <TextField
              errorMessage={errors?.appellantEmail}
              name={`${appellantTitle} Email`}
              value={virtualHearing.appellantEmail}
              required
              strongLabel
              className={[
                classnames('cf-form-textinput', 'cf-inline-field', {
                  [enablePadding]: errors?.appellantEmail
                })
              ]}
              readOnly={readOnlyEmails}
              onChange={(appellantEmail) => update('virtualHearing', { appellantEmail })}
              inputStyling={maxWidthFormInput}
            />
            <div />
            <div />
          </div>
          <div className="cf-help-divider" />
          <h3>Power of Attorney</h3>
          <div {...rowThirds}>
            <TextField
              errorMessage={errors?.representativeEmail}
              name="POA/Representative Email"
              value={virtualHearing.representativeEmail}
              strongLabel
              className={[
                classnames('cf-form-textinput', 'cf-inline-field', {
                  [enablePadding]: errors?.representativeEmail
                })
              ]}
              readOnly={readOnlyEmails}
              onChange={(representativeEmail) => update('virtualHearing', { representativeEmail })}
              inputStyling={maxWidthFormInput}
            />
            <div />
            <div />
          </div>
        </React.Fragment>
      )}
    </ContentSection>
  );
};

VirtualHearingForm.propTypes = {
  update: PropTypes.func,
  hearing: PropTypes.shape({
    appellantIsNotVeteran: PropTypes.bool,
    scheduledForIsPast: PropTypes.bool,
    wasVirtual: PropTypes.bool,
    isVirtual: PropTypes.bool
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
