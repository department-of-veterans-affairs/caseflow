import React, { Component } from 'react';
import PropTypes from 'prop-types';
import Select from 'react-select';
import _ from 'lodash';

const TAG_ALREADY_EXISTS_MSG = 'Tag already exists';
const NO_RESULTS_TEXT = 'Not an option';
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
      creatableOptions,
      searchable
    } = this.props;

    const SelectComponent = creatable ? Select.Creatable : Select;
    let addCreatableOptions = {};

    /* If the creatable option is passed in, these additional props are added to
     * the select component.
     * tagAlreadyExistsMsg: This message is used to as a message to show when a
     * custom tag entered already exits.
     * promptTextCreator: this is a function called to show the text when a tag
     * entered doesn't exist in the current list of options.
    */
    if (creatable) {
      addCreatableOptions = {
        noResultsText: _.get(
          creatableOptions, 'tagAlreadyExistsMsg', TAG_ALREADY_EXISTS_MSG
        ),

        // eslint-disable-next-line no-shadow
        newOptionCreator: ({ label, labelKey, valueKey }) => ({
          [labelKey]: _.trim(label),
          [valueKey]: _.trim(label),
          className: 'Select-create-option-placeholder'
        }),

        // eslint-disable-next-line no-shadow
        isValidNewOption: ({ label }) => label && (/\S/).test(label),

        promptTextCreator: (tagName) => `Create a tag for "${_.trim(tagName)}"`,
        ..._.pick(creatableOptions, 'promptTextCreator')
      };
    }

    // TODO We will get the "tag already exists" message even when the input is invalid,
    // because if the selector filters the options to be [], it will show the "no results found"
    // message. We can get around this by unsetting `noResultsText`.

    if (_.isEmpty(options)) {
      addCreatableOptions.noResultsText = '';
    }

    return <div className="cf-form-dropdown">
      <label className="question-label" htmlFor={name}>
        {label || name} {required && <span className="cf-required">Required</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <SelectComponent
        inputProps={{ id: name }}
        options={options}
        onChange={this.onChange}
        value={this.state.value}
        placeholder={placeholder === null ? DEFAULT_PLACEHOLDER : placeholder }
        clearable={false}
        noResultsText={noResultsText ? noResultsText : NO_RESULTS_TEXT}
        searchable={searchable}
        disabled={readOnly}
        multi={multi}
        onBlurResetsInput={false}
        tabIndex={this.props.tabIndex}
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
