import React from 'react';
import Select from 'react-select';
import { css } from 'glamor';
import PropTypes from 'prop-types';

//  this component replaces the default html select dropdown, because the original html dropdown
//  has display differences between windows and mac. Using this component gets rid of those
//  differences and matches caseflow's color scheme.

// Borrowed from TimeSelect.jsx and heavily modified to fix the theme of reader portion of caseflow.
const customSelectStyles = {
  dropdownIndicator: () => ({
    width: '80%'
  }),

  menu: () => ({
    border: '1px solid black',
  }),

  valueContainer: (styles) => ({

    ...styles,
    lineHeight: 'normal',
    // this is a hack to fix a problem with changing the height of the dropdown component.
    // Changing the height causes problems with text shifting.
    marginTop: '-10%',
    marginBottom: '-10%',
    paddingTop: '-10%',
    minHeight: '44px',

  }),
  singleValue: (styles) => {
    return {
      ...styles,
      alignContent: 'center',
    };
  },

  placeholder: (styles) => ({
    ...styles
  }),

  option: (styles, { isFocused }) => ({
    color: 'black',
    alignContent: 'center',
    backgroundColor: isFocused ? 'white' : 'null',
    ':hover': {
      ...styles[':hover'],
      backgroundColor: '#5c9ceb',
      color: 'white'
    }
  })
};

const selectContainerStyles = css({
  width: '100%',
  display: 'inline-block'
});

const ReactSelectDropdown = (props) => {
  const isDisabled = props.disabled || false;

  return (
    <div id="reactSelectContainer"
      {...selectContainerStyles}>

      <label style={{ marginTop: '5px', marginBottom: '5px', marginLeft: '1px' }}>{props.label}</label>
      <Select
        placeholder={props.customPlaceholder || 'select...'}
        options={props.options}
        defaultValue={props.defaultValue}
        onChange={props.onChangeMethod}
        styles={customSelectStyles}
        className={props.className}
        isDisabled={isDisabled}
        aria-label="dropdown"
      />
    </div>

  );
};

ReactSelectDropdown.propTypes = {
  onChange: PropTypes.func,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      value: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
      displayText: PropTypes.string,
    })
  ),
  defaultValue: PropTypes.object,
  label: PropTypes.string,
  onChangeMethod: PropTypes.func,
  className: PropTypes.string,
  disabled: PropTypes.bool,
  customPlaceholder: PropTypes.string
};

export default ReactSelectDropdown;
