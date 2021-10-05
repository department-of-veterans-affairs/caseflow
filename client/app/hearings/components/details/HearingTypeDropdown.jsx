import PropTypes from 'prop-types';
import React from 'react';

import { VIRTUAL_HEARING_LABEL } from '../../constants';
import SearchableDropdown from '../../../components/SearchableDropdown';

/**
 * Component to convert a hearing to virtual.
 */
const HearingTypeDropdown = ({
  convertHearing,
  readOnly,
  hearingTypeOptions,
  styling,
  update,
  currentOption
}) => {

  const { label: currentLabel } = currentOption;

  const onChange = () => {
    // Change from virtual if the current label is virtual
    const type = currentLabel === VIRTUAL_HEARING_LABEL ? 'change_from_virtual' : 'change_to_virtual';

    if (convertHearing) {
      convertHearing(type);
    }

    // If the current value is not virtual, we are cancelling the virtual hearing
    update('virtualHearing', { requestCancelled: currentLabel === VIRTUAL_HEARING_LABEL, jobCompleted: false });
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
  convertHearing: PropTypes.func,
  enableFullPageConversion: PropTypes.bool,
  openModal: PropTypes.func,
  hearingTypeOptions: PropTypes.string,
  readOnly: PropTypes.bool,
  styling: PropTypes.object,
  update: PropTypes.func,
  virtualHearing: PropTypes.object,
  currentOption: PropTypes.object
};

export default HearingTypeDropdown;
