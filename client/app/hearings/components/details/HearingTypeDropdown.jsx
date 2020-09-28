import PropTypes from 'prop-types';
import React from 'react';

import { VIDEO_HEARING, VIRTUAL_HEARING } from '../../constants';
import SearchableDropdown from '../../../components/SearchableDropdown';

/**
 * Component to convert a hearing to virtual.
 */
const HearingTypeDropdown = ({
  convertHearing,
  enableFullPageConversion,
  onChange,
  openModal,
  readOnly,
  requestType,
  styling,
  update,
  virtualHearing,
}) => {
  const hearingTypeOptions = [
    {
      value: false,
      label: requestType
    },
    {
      value: true,
      label: VIRTUAL_HEARING
    }
  ];

  const currentOption = (!virtualHearing || !virtualHearing.status || virtualHearing.status === 'cancelled') ?
    hearingTypeOptions[0] :
    hearingTypeOptions[1];
  const { label: currentLabel } = currentOption;

  onChange = ({ label }) => {
    // Change from virtual if the current label is virtual
    const type = currentLabel === VIRTUAL_HEARING ? 'change_from_virtual' : 'change_to_virtual';

    // Use the modal if the label is video
    if ((label === VIDEO_HEARING || currentLabel === VIDEO_HEARING) && !enableFullPageConversion) {
      openModal({ type });
    } else if (convertHearing) {
      convertHearing(type);
    }

    // If the current value is not virtual, we are cancelling the virtual hearing
    update('virtualHearing', { requestCancelled: currentLabel === VIRTUAL_HEARING, jobCompleted: false });
  };

  return (
    <SearchableDropdown
      label="Hearing Type"
      name="hearingType"
      strongLabel
      options={hearingTypeOptions.filter((opt) => opt.label !== currentLabel)}
      value={currentOption}
      onChange={onChange}
      readOnly={readOnly}
      styling={styling}
    />
  );
};

HearingTypeDropdown.propTypes = {
  enableFullPageConversion: PropTypes.bool,
  virtualHearing: PropTypes.object,
  update: PropTypes.func,
  openModal: PropTypes.func,
  convertHearing: PropTypes.func,
  requestType: PropTypes.string,
  readOnly: PropTypes.bool,
  styling: PropTypes.object
};

export default HearingTypeDropdown;
