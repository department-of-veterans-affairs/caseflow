import PropTypes from 'prop-types';
import React, { useContext } from 'react';
import classnames from 'classnames';

import { ContentSection } from '../../../components/ContentSection';
import { HearingLinks } from './HearingLinks';
import { HearingsUserContext } from '../../contexts/HearingsUserContext';
import { UPDATE_VIRTUAL_HEARING } from '../../contexts/HearingsFormContext';
import { enablePadding, maxWidthFormInput, rowThirds } from './style';
import { getAppellantTitleForHearing } from '../../utils';
import TextField from '../../../components/TextField';

export const VirtualHearingForm = (
  { hearing, virtualHearing, isVirtual, wasVirtual, readOnly, dispatch, errors }
) => {
  if (!isVirtual && !wasVirtual) {
    return null;
  }

  const showEmailFields = (isVirtual || wasVirtual) && virtualHearing;
  const readOnlyEmails = readOnly || !virtualHearing?.jobCompleted || wasVirtual || hearing.scheduledForIsPast;
  const appellantTitle = getAppellantTitleForHearing(hearing);
  const user = useContext(HearingsUserContext);

  return (
    <ContentSection
      header={`${wasVirtual ? 'Previous ' : ''}Virtual Hearing Details`}
    >
      <HearingLinks
        user={user}
        hearing={hearing}
        virtualHearing={virtualHearing}
        isVirtual={isVirtual}
        wasVirtual={wasVirtual}
      />
      {showEmailFields && (
        <React.Fragment>
          <div className="cf-help-divider" />
          <h3>{appellantTitle}</h3>
          <div {...rowThirds}>
            <TextField
              errorMessage={errors?.appellantEmail}
              name={`${appellantTitle} Email for Notifications`}
              value={virtualHearing.appellantEmail}
              required
              strongLabel
              className={[
                classnames('cf-form-textinput', 'cf-inline-field', {
                  [enablePadding]: errors?.appellantEmail
                })
              ]}
              readOnly={readOnlyEmails}
              onChange={
                (appellantEmail) => dispatch({
                  type: UPDATE_VIRTUAL_HEARING,
                  payload: { appellantEmail }
                })
              }
              inputStyling={maxWidthFormInput}
            />
            <div />
            <div />
          </div>
          <div className="cf-help-divider" />
          <h3>Power of Attorney</h3>
          <div {...rowThirds}>
            <TextField
              errorMessage={errors?.repEmail}
              name="POA/Representative Email for Notifications"
              value={virtualHearing.representativeEmail}
              strongLabel
              className={[classnames('cf-form-textinput', 'cf-inline-field')]}
              readOnly={readOnlyEmails}
              onChange={
                (representativeEmail) => dispatch({
                  type: UPDATE_VIRTUAL_HEARING,
                  payload: { representativeEmail }
                })
              }
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
  dispatch: PropTypes.func,
  hearing: PropTypes.shape({
    appellantIsNotVeteran: PropTypes.bool,
    scheduledForIsPast: PropTypes.bool
  }),
  isVirtual: PropTypes.bool,
  readOnly: PropTypes.bool,
  virtualHearing: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string,
    jobCompleted: PropTypes.bool
  }),
  errors: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string
  }),
  wasVirtual: PropTypes.bool
};
