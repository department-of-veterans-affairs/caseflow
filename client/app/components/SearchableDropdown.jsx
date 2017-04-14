import React, { Component, PropTypes } from 'react';
import Select from 'react-select';

const TAG_ALREADY_EXISTS_MSG = "Tag already exists";
const DEFAULT_PROMPT_TEXT_CREATOR_FUNCTION = (label) => {return `Create a tag for "${label}"`};
const DEFAULT_PLACEHOLDER = "Select option";

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
    if (!this.props.multi && Array.isArray(value) && value.length <= 0) {
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
      multi,
      name,
      noResultsText,
      required,
      readOnly,
      creatable,
      creatableOptions
    } = this.props;

    let Component = creatable ? Select.Creatable : Select;
    let addCreatableOptions = {};

    if (creatable) {
      addCreatableOptions = {
        noResultsText: (creatableOptions && creatableOptions.tagAlreadyExistsMsg) ?
          creatableOptions.tagAlreadyExistsMsg : TAG_ALREADY_EXISTS_MSG,
        promptTextCreator: (creatableOptions && creatableOptions.promptTextCreator) ?
          creatableOptions.promptTextCreator : DEFAULT_PROMPT_TEXT_CREATOR_FUNCTION          
      }
    }

    return <div className="cf-form-dropdown">
      <label className="question-label" htmlFor={name}>
        {label || name} {required && <span className="cf-required">Required</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <Component
        id={name}
        value={this.state.value}
        options={options}
        onChange={this.onChange}
        placeholder={placeholder ? placeholder : DEFAULT_PLACEHOLDER}
        clearable={false}
        noResultsText={noResultsText ? noResultsText : TAG_ALREADY_EXISTS_MSG}
        disabled={readOnly}
        multi={multi}
        {...addCreatableOptions}
      />
    </div>;
  }
}

SearchableDropdown.propTypes = {
  creatable: PropTypes.bool,
  errorMessage: PropTypes.string,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.array,
  readOnly: PropTypes.bool,
  required: PropTypes.bool,
  placeholder: PropTypes.string,
  creatableOptions: PropTypes.shape({
    tagAlreadyExistsMsg: PropTypes.string,
    promptTextCreator: PropTypes.func
  })
};

export default SearchableDropdown;
