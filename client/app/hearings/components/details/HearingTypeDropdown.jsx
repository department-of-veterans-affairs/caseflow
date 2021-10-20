import PropTypes from 'prop-types';
import React from 'react';
import SearchableDropdown from '../../../components/SearchableDropdown';

/**
 * Component to convert a hearing to virtual.
 */
const HearingTypeDropdown = ({
  dropdownOptions,
  currentOption,
  onChange,
  readOnly,
  styling
}) =>

  <SearchableDropdown
    label="Hearing Type"
    name="hearingType"
    strongLabel
    options={dropdownOptions}
    value={currentOption}
    onChange={onChange}
    readOnly={readOnly}
    styling={styling}
  />;

HearingTypeDropdown.propTypes = {
  dropdownOptions: PropTypes.object,
  currentOption: PropTypes.object,
  onChange: PropTypes.func,
  readOnly: PropTypes.bool,
  styling: PropTypes.object,
};

export default HearingTypeDropdown;
