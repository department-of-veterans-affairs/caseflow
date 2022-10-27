import { sprintf } from 'sprintf-js';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React, { useState, useContext, useEffect } from 'react';

import HearingTypeConversionContext, { updateAppealDispatcher } from '../contexts/HearingTypeConversionContext';
import { VSOAppellantSection } from './VirtualHearings/VSOAppellantSection';
import { VSORepresentativeSection } from './VirtualHearings/VSORepresentativeSection';
import { getAppellantTitle } from '../utils';
import { marginTop, saveButton, cancelButton } from './details/style';
import Checkbox from '../../components/Checkbox';
import Button from '../../components/Button';
import Link from '../../components/Link';
import COPY from '../../../COPY';
export const VSOHearingTypeConversionForm = ({
  isLoading,
  onCancel,
  onSubmit,
  type
}) => {
  const {
    updatedAppeal,
    dispatchAppeal,
    isValidEmail,
    setIsValidEmail
  } = useContext(HearingTypeConversionContext);

  const updateAppeal = updateAppealDispatcher(updatedAppeal, dispatchAppeal);

  // initialize hook to manage state of affirm permissisons checkbox
  const [checkedPermissions, setCheckedPermissions] = useState(false);

  // initialize hook to manage state of affirm access checkbox
  const [checkedAccess, setCheckedAccess] = useState(false);

  // 'Appellant' or 'Veteran'
  const appellantTitle = getAppellantTitle(updatedAppeal?.appellantIsNotVeteran);

  // powerOfAttorney gets loaded into redux store when case details page loads
  const hearing = {
    /* eslint-disable camelcase */
    representative: updatedAppeal?.powerOfAttorney?.representative_name,
    representativeType: updatedAppeal?.powerOfAttorney?.representative_type,
    /* eslint-enable camelcase */
    appellantFullName: updatedAppeal?.appellantFullName,
    appellantIsNotVeteran: updatedAppeal?.appellantIsNotVeteran,
    veteranFullName: updatedAppeal?.veteranFullName,
    appellantTz: updatedAppeal?.appellantTz,
    appellantEmailAddress: updatedAppeal?.appellantEmailAddress,
    representativeEmailAddress: updatedAppeal?.currentUserEmail,
    representativeTz: updatedAppeal?.representativeTz,
    appellantConfirmEmailAddress: updatedAppeal?.appellantConfirmEmailAddress
  };

  // Set the section props
  const sectionProps = {
    appellantTitle,
    hearing,
    readOnly: true,
    showDivider: false,
    showOnlyAppellantName: true,
    showMissingEmailAlert: true,
    actionType: 'appeal',
    update: updateAppeal,
    setIsValidEmail,
    type
  };
  const convertTitle = sprintf(COPY.CONVERT_HEARING_TYPE_TITLE, type);

  const prefillFields = () => {
    updateAppeal(
      'appeal', {
        ...updatedAppeal,
        representativeTz: updatedAppeal.currentUserTimezone
      });
  };

  useEffect(() => {
    // Ensure representative timezone is populated.
    prefillFields();
  }, []);

  const preventSubmission = () => {
    return !isValidEmail ||
      !updatedAppeal?.appellantEmailAddress ||
      !checkedAccess ||
      !checkedPermissions ||
      !updatedAppeal?.appellantTz ||
      !updatedAppeal?.representativeTz ||
      (updatedAppeal?.appellantEmailAddress !==
        updatedAppeal?.appellantConfirmEmailAddress
      );
  };

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
          value = {checkedPermissions}
          onChange={() => setCheckedPermissions(!checkedPermissions)}
        />
        <div />
        <Checkbox
          label={
            <div>
              <span>{COPY.CONVERT_HEARING_TYPE_CHECKBOX_AFFIRM_ACCESS}</span>&nbsp;
              <Link href="https://www.bva.va.gov/docs/VirtualHearing_FactSheet.pdf" target="_blank">
                Learn more
              </Link>
            </div>
          }
          name="Affirm Access"
          value = {checkedAccess}
          onChange={() => setCheckedAccess(!checkedAccess)}
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
            disabled={preventSubmission()}
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
  type: PropTypes.oneOf(['Virtual']),
  isLoading: PropTypes.bool,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
