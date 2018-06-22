import React from 'react';
import PropTypes from 'prop-types';

export default class Dropdown extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  }

  render() {
    let {
      name,
      options,
      value,
      defaultText
    } = this.props;

    value = (value === null || typeof value === 'undefined') ? '' : value;

    return <select value={value} onChange={this.onChange} id={name} className="usa-button-outline usa-button">
      { defaultText && <option defaultValue hidden>{defaultText}</option>}
      {options.map((option, index) =>
        <option
          value={option.value}
          id={`${name}_${option.value}`}
          key={index}>{option.displayText}
        </option>
      )}
    </select>;
  }
}

Dropdown.propTypes = {
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.array.isRequired,
  value: PropTypes.string
};
