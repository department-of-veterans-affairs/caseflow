import React, { useState } from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';

import { marginTop, saveButton, cancelButton } from './details/style';
import { HelperText } from './VirtualHearings/HelperText';
import COPY from '../../../COPY';
import { getAppellantTitle } from '../utils';
import { RepresentativeSection } from './VirtualHearings/RepresentativeSection';
import { AppellantSection } from './VirtualHearings/AppellantSection';
import Button from '../../components/Button';

export const HearingTypeConversionForm = ({
  type,
  appeal
}) => {
  // Create and manage the loading state
  const [loading, setLoading] = useState(false);

  // reset any states
  const reset = () => setLoading(false);

  // 'Appellant' or 'Veteran'
  const appellantTitle = getAppellantTitle(appeal?.appellantIsNotVeteran);

  /* eslint-disable camelcase */
  // powerOfAttorney gets loaded into redux store when case details page loads
  const hearing = {
    representative: appeal?.powerOfAttorney?.representative_name,
    representativeType: appeal?.powerOfAttorney?.representative_type,
    appellantFullName: appeal?.appellantFullName
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

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <h1 className="cf-margin-bottom-0">{convertTitle}</h1>
        <p dangerouslySetInnerHTML={
          { __html: sprintf(COPY.CONVERT_HEARING_TYPE_SUBTITLE, appeal?.closestRegionalOfficeLabel ?? '') }
        }
        />
        <HelperText label={COPY.CONVERT_HEARING_TYPE_SUBTITLE_2} />
        <AppellantSection {...sectionProps} />
        <RepresentativeSection {...sectionProps} />
      </AppSegment>
      <div {...marginTop(30)}>
        <Button
          name="Cancel"
          linkStyling
          onClick={
            () => {
              reset();
              history.goBack();
            }
          }
          styling={cancelButton}
        >
          Cancel
        </Button>
        <span {...saveButton}>
          <Button
            name={convertTitle}
            loading={loading}
            className="usa-button"
          >
            {convertTitle}
          </Button>
        </span>
      </div>
    </React.Fragment>
  );
};

HearingTypeConversionForm.propTypes = {
  appeal: PropTypes.object,
  // Router inherited props
  history: PropTypes.object,
  type: PropTypes.string
};
