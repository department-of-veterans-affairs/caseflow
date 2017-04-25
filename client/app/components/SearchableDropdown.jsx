import React, { Component, PropTypes } from 'react';
import Select from 'react-select';
import _ from 'lodash';

const TAG_ALREADY_EXISTS_MSG = 'Tag already exists';
const NO_RESULTS_TEXT = 'Not an option';
const DEFAULT_PROMPT_TEXT_CREATOR_FUNCTION =
  (label) => `Create a tag for "${label}"`;

const DEFAULT_PLACEHOLDER = 'Select option';

class SearchableDropdown extends Component {

  constructor(props) {
    super(props);
    this.state = {
      value: props.value || null
    };
  }

  componentWillReceiveProps = (nextProps) => {
    this.setState({ value: nextProps.value || null });
  };

  onChange = (value) => {
    let newValue = value;
    let deletedValue = null;

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
    // don't set value in state if creatable is true
    if (!this.props.selfManageValueState) {
      this.setState({ value: newValue });
    }

    if (this.state.value && value.length < this.state.value.length) {
      deletedValue = _.differenceWith(this.state.value, value, _.isEqual);
    }
    if (this.props.onChange) {
      this.props.onChange(newValue, deletedValue);
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

    const SelectComponent = creatable ? Select.Creatable : Select;
    let addCreatableOptions = {};

    /* If the creatable option is passed in, these additonal props are added to
     * the select component.
     * tagAlreadyExistsMsg: This message is used to as a message to show when a
     * custom tag entered already exits.
     * promptTextCreator: this is a function called to show the text when a tag
     * entered doesn't exist in the current list of options.
    */
    if (creatable) {
      addCreatableOptions = {
        noResultsText: (creatableOptions && creatableOptions.tagAlreadyExistsMsg) ?
          creatableOptions.tagAlreadyExistsMsg : TAG_ALREADY_EXISTS_MSG,
        promptTextCreator: (creatableOptions && creatableOptions.promptTextCreator) ?
          creatableOptions.promptTextCreator : DEFAULT_PROMPT_TEXT_CREATOR_FUNCTION
      };
    }

    if (_.isEmpty(options)) {
      addCreatableOptions.noResultsText = '';
    }

    return <div className="cf-form-dropdown">
      <label className="question-label" htmlFor={name}>
        {label || name} {required && <span className="cf-required">Required</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <SelectComponent
        id={name}
        options={options}
        onChange={this.onChange}
        value={this.state.value}
        placeholder={placeholder === null ? DEFAULT_PLACEHOLDER : placeholder }
        clearable={false}
        noResultsText={noResultsText ? noResultsText : NO_RESULTS_TEXT}
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
