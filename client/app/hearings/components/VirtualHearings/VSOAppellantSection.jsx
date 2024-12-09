import React from 'react';
import PropTypes from 'prop-types';
import { VirtualHearingSection } from './Section';
import { ReadOnly } from '../details/ReadOnly';
import { VSOEmailNotificationsFields } from '../details/VSOEmailNotificationsFields';
export const VSOAppellantSection = ({
  errors,
  hearing,
  showDivider,
  appellantTitle,
  formFieldsOnly,
  setIsValidEmail,
  update,
  actionType,
  hearingDayDate
}) => {
  // Depending on where this component is used, the *FullName fields will be available.
  // If they aren't, the *FirstName/*LastName fields should be available.
  const appellantName = hearing?.appellantIsNotVeteran ?
    hearing?.appellantFullName ||
    `${hearing?.appellantFirstName} ${hearing?.appellantLastName}` :
    hearing?.veteranFullName ||
    `${hearing?.veteranFirstName} ${hearing?.veteranLastName}`;

  return (
    <VirtualHearingSection
      formFieldsOnly={formFieldsOnly}
      label={appellantTitle}
      showDivider={showDivider}
    >
      <React.Fragment>
        <ReadOnly label={`${appellantTitle} Name`} text={appellantName} />
        <VSOEmailNotificationsFields
          hearing={hearing}
          update={update}
          setIsValidEmail={setIsValidEmail}
          actionType={actionType}
          errors={errors}
          hearingDayDate={hearingDayDate}
        />
      </React.Fragment>
    </VirtualHearingSection>
  );
};

VSOAppellantSection.defaultProps = {
  schedulingToVirtual: true,
  hearingsForm: false
};

VSOAppellantSection.propTypes = {
  hearing: PropTypes.object,
  errors: PropTypes.object,
  type: PropTypes.string,
  update: PropTypes.func,
  readOnly: PropTypes.bool,
  fullWidth: PropTypes.bool,
  appellantTitle: PropTypes.string,
  showOnlyAppellantName: PropTypes.bool,
  showDivider: PropTypes.bool,
  showMissingEmailAlert: PropTypes.bool,
  showTimezoneField: PropTypes.bool,
  virtual: PropTypes.bool,
  userCanCollectVideoCentralEmails: PropTypes.bool,
  schedulingToVirtual: PropTypes.bool,
  formFieldsOnly: PropTypes.bool,
  setIsValidEmail: PropTypes.func,
  actionType: PropTypes.string,
  hearingDayDate: PropTypes.string
};
