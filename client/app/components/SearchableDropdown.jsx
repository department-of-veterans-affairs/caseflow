import React, { Component, PropTypes } from 'react';
import Select from 'react-select';

class SearchableDropdown extends Component {

  constructor(props) {
    super(props);
    this.state = {
      value: null
    };
  }

  onChange = (value) => {
    let newValue = value;

    /*
     * this is a temp fix for react-select value backspace
     * issue.
     * Setting value to null when an option is deselected
     * using the backspace.
     * https://github.com/JedWatson/react-select/pull/773
     */

    if (Array.isArray(value) && value.length <= 0) {
      newValue = null;
    }
    this.setState({ value: newValue });
    if (this.props.onChange) {
      this.props.onChange(newValue);
    }
  }

  render() {
    const {
      options,
      placeholder,
      errorMessage,
      label,
      name,
      required,
      readOnly
    } = this.props;

    return <div className="cf-form-dropdown">
      <label className="question-label" htmlFor={name}>
        {label || name} {required && <span className="cf-required">Required</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <Select
        id={name}
        value={this.state.value}
        options={options}
        onChange={this.onChange}
        placeholder={placeholder ? placeholder : "Select option"}
        clearable={false}
        noResultsText="Not an option"
        disabled={readOnly}
      />
    </div>;
  }
}

SearchableDropdown.propTypes = {
  errorMessage: PropTypes.string,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.array,
  readOnly: PropTypes.bool,
  required: PropTypes.bool,
  placeholder: PropTypes.string
};

export default SearchableDropdown;
