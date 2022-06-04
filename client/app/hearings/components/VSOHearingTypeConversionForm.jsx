import { sprintf } from 'sprintf-js';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React from 'react';
import { VSOAppellantSection } from './VirtualHearings/VSOAppellantSection';
import { VSORepresentativeSection } from './VirtualHearings/VSORepresentativeSection';
import { getAppellantTitle } from '../utils';
import { marginTop, saveButton, cancelButton } from './details/style';
import Checkbox from '../../components/Checkbox';
import Button from '../../components/Button';
import COPY from '../../../COPY';
export const VSOHearingTypeConversionForm = ({
  appeal,
  isLoading,
  onCancel,
  onSubmit,
  type,
}) => {
  // 'Appellant' or 'Veteran'
  const appellantTitle = getAppellantTitle(appeal?.appellantIsNotVeteran);

  /* eslint-disable camelcase */
  // powerOfAttorney gets loaded into redux store when case details page loads
  const hearing = {
    representative: appeal?.powerOfAttorney?.representative_name,
    representativeEmail: appeal?.powerOfAttorney?.representative_email_address,
    representativeType: appeal?.powerOfAttorney?.representative_type,
    appellantFullName: appeal?.appellantFullName,
    appellantIsNotVeteran: appeal?.appellantIsNotVeteran,
    veteranFullName: appeal?.veteranFullName,
    currentUserEmail: appeal?.currentUserEmail,
    currentUserTimezone: appeal?.currentUserTimezone,
    appellantTz: appeal?.appellantTz,
    appellantTitle
  };

  // veteranInfo gets loaded into redux store when case details page loads
  const virtualHearing = {
    appellantEmail: appeal?.veteranInfo?.veteran?.email_address,
    representativeEmail: appeal?.powerOfAttorney?.representative_email_address,
  };

  /* eslint-enable camelcase */
  // Set the section props
  const sectionProps = {
    appellantTitle,
    hearing,
    readOnly: true,
    showDivider: false,
    showOnlyAppellantName: true,
    showMissingEmailAlert: true,
    // props to populate form
    appellantEmailAddress: appeal?.appellantEmailAddress,
    appellantTz: appeal?.appellantTz,
    type,
    virtualHearing,
  };

  const convertTitle = sprintf(COPY.CONVERT_HEARING_TYPE_TITLE, type);

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <h1 className="cf-margin-bottom-0">{convertTitle}</h1>
        <p>{COPY.CONVERT_HEARING_TYPE_SUBTITLE_3}</p>
        <VSOAppellantSection {...sectionProps} />
        <VSORepresentativeSection {...sectionProps} showDivider />
        <Checkbox
          label={COPY.CONVERT_HEARING_TYPE_CHECKBOX_AFFIRM_PERMISSION}
          name="Affirm Permission"
          value
          onChange
        />
        <div />
        <Checkbox
          label={
            <div>
              <span>{COPY.CONVERT_HEARING_TYPE_CHECKBOX_AFFIRM_ACCESS}</span>
              <a
                href="https://www.bva.va.gov/docs/VirtualHearing_FactSheet.pdf"
                style={{ textDecoration: 'underline' }}
              >
                Learn more
              </a>
            </div>
          }
          name="Affirm Access"
          value
          onChange
        />
      </AppSegment>
      <div {...marginTop(30)}>
        <Button
          name="Cancel"
          linkStyling
          onClick={onCancel}
          styling={cancelButton}
        >
          Cancel
        </Button>
        <span {...saveButton}>
          <Button
            name={convertTitle}
            loading={isLoading}
            className="usa-button"
            onClick={onSubmit}
          >
            {convertTitle}
          </Button>
        </span>
      </div>
    </React.Fragment>
  );
};

VSOHearingTypeConversionForm.defaultProps = {
  isLoading: false,
};

VSOHearingTypeConversionForm.propTypes = {
  appeal: PropTypes.object,
  type: PropTypes.oneOf(['Virtual']),
  isLoading: PropTypes.bool,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
