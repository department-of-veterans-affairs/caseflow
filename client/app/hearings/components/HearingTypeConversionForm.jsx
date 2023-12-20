import { sprintf } from 'sprintf-js';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React from 'react';

import { AppellantSection } from './VirtualHearings/AppellantSection';
import { HelperText } from './VirtualHearings/HelperText';
import { RepresentativeSection } from './VirtualHearings/RepresentativeSection';
import { getAppellantTitle } from '../utils';
import { marginTop, saveButton, cancelButton } from './details/style';
import Button from '../../components/Button';
import COPY from '../../../COPY';

export const HearingTypeConversionForm = ({
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
    representativeType: appeal?.powerOfAttorney?.representative_type,
    appellantFullName: appeal?.appellantFullName,
    appellantIsNotVeteran: appeal?.appellantIsNotVeteran,
    veteranFullName: appeal?.veteranFullName,
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
    type,
    virtualHearing,
  };

  const convertTitle = sprintf(COPY.CONVERT_HEARING_TYPE_TITLE, type);
  const convertSubtitle = sprintf(
    COPY.CONVERT_HEARING_TYPE_SUBTITLE,
    appeal?.closestRegionalOfficeLabel ?
      `<strong>${appeal.closestRegionalOfficeLabel}</strong>` :
      COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT
  );

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <h1 className="cf-margin-bottom-0">{convertTitle}</h1>
        <p dangerouslySetInnerHTML={{ __html: convertSubtitle }} />
        <HelperText label={COPY.CONVERT_HEARING_TYPE_SUBTITLE_2} />
        <AppellantSection {...sectionProps} />
        <RepresentativeSection {...sectionProps} showDivider />
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

HearingTypeConversionForm.defaultProps = {
  isLoading: false
};

HearingTypeConversionForm.propTypes = {
  appeal: PropTypes.object,
  type: PropTypes.oneOf(['Virtual']),
  isLoading: PropTypes.bool,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func
};
