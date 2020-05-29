import PropTypes from 'prop-types';
import React, { useContext } from 'react';
import classnames from 'classnames';

import { ContentSection } from '../../../components/ContentSection';
import { HearingLinks } from './HearingLinks';
import { HearingsUserContext } from '../../contexts/HearingsUserContext';
import { UPDATE_VIRTUAL_HEARING } from '../../contexts/HearingsFormContext';
import {
  VIRTUAL_HEARING_HOST,
  getAppellantTitleForHearing,
  virtualHearingRoleForUser,
} from '../../utils';
import {
  enablePadding,
  maxWidthFormInput,
  rowThirdsWithFinalSpacer,
} from './style';
import COPY from '../../../../COPY.json';
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
  const virtualHearingLabel =
    virtualHearingRoleForUser(user, hearing) === VIRTUAL_HEARING_HOST ?
      COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL :
      COPY.REPRESENTATIVE_VIRTUAL_HEARING_LINK_LABEL;

  return (
    <ContentSection
      header={`${wasVirtual ? 'Previous ' : ''}Virtual Hearing Details`}
    >
      <HearingLinks
        user={user}
        label={virtualHearingLabel}
        hearing={hearing}
        virtualHearing={virtualHearing}
        isVirtual={isVirtual}
        wasVirtual={wasVirtual}
      />
      {showEmailFields && (
        <div {...rowThirdsWithFinalSpacer}>
          <TextField
            errorMessage={errors?.appellantEmail}
            name={`${appellantTitle} Email for Notifications`}
            value={virtualHearing.appellantEmail}
            strongLabel
            className={[
              classnames('cf-form-textinput', 'cf-inline-field', {
                [enablePadding]: errors?.appellantEmail
              })
            ]}
            readOnly={readOnlyEmails}
            onChange={(appellantEmail) => dispatch({ type: UPDATE_VIRTUAL_HEARING, payload: { appellantEmail } })}
            inputStyling={maxWidthFormInput}
          />
          <TextField
            errorMessage={errors?.repEmail}
            name="POA/Representative Email for Notifications"
            value={virtualHearing.representativeEmail}
            strongLabel
            className={[classnames('cf-form-textinput', 'cf-inline-field')]}
            readOnly={readOnlyEmails}
            onChange={(representativeEmail) => dispatch({ type: UPDATE_VIRTUAL_HEARING, payload: { representativeEmail } })}
            inputStyling={maxWidthFormInput}
          />
          <div />
        </div>
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
