import { sprintf } from 'sprintf-js';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React, { useState, createContext } from 'react';

import { VSOAppellantSection } from './VirtualHearings/VSOAppellantSection';
import { VSORepresentativeSection } from './VirtualHearings/VSORepresentativeSection';
import { getAppellantTitle } from '../utils';
import { marginTop, saveButton, cancelButton } from './details/style';
import Checkbox from '../../components/Checkbox';
import Button from '../../components/Button';
import COPY from '../../../COPY';

export const BtnContext = createContext([{}, () => {}]);

export const VSOHearingTypeConversionForm = ({
  appeal,
  isLoading,
  onCancel,
  onSubmit,
  type,
}) => {

  // initiliaze hook to manage state for email validation
  const [isNotValidEmail, setIsNotValidEmail] = useState(true);

  // initialize hook to manage state of affirm permissisons checkbox
  const [checkedPermissions, setCheckedPermissions] = useState(false);

  const checkHandlerPermissions = () => {
    setCheckedPermissions(!checkedPermissions);
  };

  // initialize hook to manage state of affirm access checkbox
  const [checkedAccess, setCheckedAccess] = useState(false);

  const checkHandlerAccess = () => {
    setCheckedAccess(!checkedAccess);
  };

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
    appellantEmail: appeal?.veteranInfo?.veteran?.email_address, // timezone here?
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
    <BtnContext.Provider value={[isNotValidEmail, setIsNotValidEmail]}>
      <React.Fragment>
        <AppSegment filledBackground>
          <h1 className="cf-margin-bottom-0">{convertTitle}</h1>
          <p>{COPY.CONVERT_HEARING_TYPE_SUBTITLE_3}</p>
          <VSOAppellantSection {...sectionProps} />
          <VSORepresentativeSection {...sectionProps} showDivider />
          <Checkbox
            label={COPY.CONVERT_HEARING_TYPE_CHECKBOX_AFFIRM_PERMISSION}
            name="affirmPermission"
            value = {checkedPermissions}
            onChange = {checkHandlerPermissions}
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
            name="affirmAccess"
            value = {checkedAccess}
            onChange = {checkHandlerAccess}
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
              disabled={isNotValidEmail || !checkedAccess || !checkedPermissions}
            >
              {convertTitle}
            </Button>
          </span>
        </div>
      </React.Fragment>
    </BtnContext.Provider>
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
