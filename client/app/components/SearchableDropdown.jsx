import * as React from 'react';
import PropTypes from 'prop-types';
import Select from 'react-select';
import AsyncSelect from 'react-select/async';
import CreatableSelect from 'react-select/creatable';
import _, { isPlainObject, isNull } from 'lodash';
import classNames from 'classnames';
import { css } from 'glamor';

const TAG_ALREADY_EXISTS_MSG = 'Tag already exists';
const NO_RESULTS_TEXT = 'Not an option';
const DEFAULT_PLACEHOLDER = 'Select option';

const customStyles = {
  input: () => ({
    height: '44px',
  }),
};

export class SearchableDropdown extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: props.value,
    };
  }

  // eslint-disable-next-line camelcase
  UNSAFE_componentWillReceiveProps = (nextProps) => {
    this.setState({ value: nextProps.value });
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
    } else if (this.props.multi && value === null) {
      // Fix for https://github.com/JedWatson/react-select/issues/3632
      newValue = [];
    }
    // don't set value in state if creatable is true
    if (!this.props.selfManageValueState) {
      this.setState({ value: this.props.clearOnSelect ? null : newValue });
    }

    if (
      this.state.value &&
      newValue &&
      Array.isArray(newValue) &&
      Array.isArray(this.state.value) &&
      newValue.length < this.state.value.length
    ) {
      deletedValue = _.differenceWith(this.state.value, newValue, _.isEqual);
    }
    if (this.props.onChange) {
      this.props.onChange(newValue, deletedValue);
    }
  };

  // Override the default keys to create a new tag (allows creating options that contain a comma)
  shouldKeyDownEventCreateNewOption = ({ keyCode }) => {
    switch (keyCode) {
    // Tab and Enter only
    case 9:
    case 13:
      return true;
    default:
      return false;
    }
  };

  getSelectComponent = () => {
    if (this.props.creatable) {
      return CreatableSelect;
    } else if (this.props.async) {
      return AsyncSelect;
    }

    return Select;
  };

  render() {
    const {
      async,
      options,
      defaultOptions,
      filterOption,
      isClearable,
      loading,
      placeholder,
      errorMessage,
      label,
      strongLabel,
      hideLabel,
      multi,
      name,
      noResultsText,
      required,
      readOnly,
      creatable,
      creatableOptions,
      searchable,
      styling,
    } = this.props;

    const dropdownStyling = css(styling, {
      '& .cf-select__menu': this.props.dropdownStyling,
    });

    const SelectComponent = this.getSelectComponent();
    let addCreatableOptions = {};
    const dropdownClasses = classNames('cf-form-dropdown', `dropdown-${name}`);
    const labelClasses = classNames('question-label', {
      'usa-sr-only': hideLabel,
    });

    // `react-select` used to accept plain string values, but now requires passing the object
    // This allows `SearchableDropdown` to still accept the legacy syntax
    const value =
      Array.isArray(this.state.value) ||
      isPlainObject(this.state.value) ||
      isNull(this.state.value) ?
        this.state.value :
        (options || []).find(({ value: val }) => val === this.state.value);

    /* If the creatable option is passed in, these additional props are added to
     * the select component.
     * noResultsText: This message is used to as a message to show when a
     * custom tag entered already exits.
     * formatCreateLabel: this is a function called to show the text when a tag
     * entered doesn't exist in the current list of options.
     */
    if (creatable) {
      addCreatableOptions = {
        noResultsText: TAG_ALREADY_EXISTS_MSG,

        // eslint-disable-next-line no-shadow
        isValidNewOption: (inputValue) => inputValue && (/\S/).test(inputValue),

        formatCreateLabel: (tagName) => `Create a tag for "${_.trim(tagName)}"`,

        ...creatableOptions,
      };
    }

    // We will get the "tag already exists" message even when the input is invalid,
    // because if the selector filters the options to be [], it will show the "no results found"
    // message. We can get around this by unsetting `noResultsText`.
    const handleNoOptions = () =>
      noResultsText ?? (creatable ? null : NO_RESULTS_TEXT);

    const labelContents = (
      <span>
        {label || name}
        {required && <span className="cf-required">Required</span>}
      </span>
    );

    return (
      <div className={dropdownClasses} {...dropdownStyling}>
        <label className={labelClasses} htmlFor={name}>
          {strongLabel ? <strong>{labelContents}</strong> : labelContents}
        </label>
        <div className={errorMessage ? 'usa-input-error' : ''}>
          {errorMessage && (
            <span className="usa-input-error-message">{errorMessage}</span>
          )}
          <div className="cf-select">
            <SelectComponent
              classNamePrefix="cf-select"
              inputId={name}
              options={options}
              defaultOptions={defaultOptions}
              filterOption={filterOption}
              loadOptions={async}
              isLoading={loading}
              onChange={this.onChange}
              value={value}
              placeholder={
                placeholder === null ? DEFAULT_PLACEHOLDER : placeholder
              }
              isClearable={isClearable}
              noOptionsMessage={handleNoOptions}
              searchable={searchable}
              isDisabled={readOnly}
              isMulti={multi}
              isSearchable={!readOnly}
              cache={false}
              onBlurResetsInput={false}
              shouldKeyDownEventCreateNewOption={
                this.shouldKeyDownEventCreateNewOption
              }
              styles={customStyles}
              {...addCreatableOptions}
            />
          </div>
        </div>
      </div>
    );
  }
}

const SelectOpts = PropTypes.arrayOf(
  PropTypes.shape({
    value: PropTypes.any,
    label: PropTypes.string,
  })
);

SearchableDropdown.propTypes = {
  async: PropTypes.func,

  /**
   * If set to true, it will provide an "X" button that allows user to clear the field
   * This will return `null` to the `onChange` callback
   * Design suggests enabling this in all instances unless there is no meaningful null/empty selection
   */
  isClearable: PropTypes.bool,
  clearOnSelect: PropTypes.bool,
  creatable: PropTypes.bool,
  creatableOptions: PropTypes.shape({
    noResultsText: PropTypes.string,
    isValidNewOption: PropTypes.func,
    formatCreateLabel: PropTypes.func,
  }),
  defaultOptions: PropTypes.oneOfType([SelectOpts, PropTypes.bool]),
  dropdownStyling: PropTypes.object,
  errorMessage: PropTypes.string,
  filterOption: PropTypes.func,
  label: PropTypes.string,
  strongLabel: PropTypes.bool,
  hideLabel: PropTypes.bool,
  loading: PropTypes.bool,
  multi: PropTypes.bool,
  name: PropTypes.string.isRequired,

  /**
 * react-select will by default set noResultsText to say "No options" unless the prop is explicitly defined
 */
  noResultsText: PropTypes.string,
  onChange: PropTypes.func,
  options: SelectOpts,
  placeholder: PropTypes.oneOfType([PropTypes.string, PropTypes.object]),
  readOnly: PropTypes.bool,
  required: PropTypes.bool,
  searchable: PropTypes.bool,
  selfManageValueState: PropTypes.bool,
  styling: PropTypes.object,
  value: PropTypes.oneOfType([PropTypes.object, PropTypes.string]),
};

/* eslint-disable no-undefined */
SearchableDropdown.defaultProps = {
  clearOnSelect: false,
  loading: false,
  filterOption: undefined,
  filterOptions: undefined,
};
/* eslint-enable no-undefined */

export default SearchableDropdown;
