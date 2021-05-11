import * as React from 'react';
import PropTypes from 'prop-types';
import Select, { components } from 'react-select';
import AsyncSelect from 'react-select/async';
import CreatableSelect from 'react-select/creatable';
import _, { isPlainObject, isNull, kebabCase } from 'lodash';
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

const CustomMenuList = (props) => {
  const innerProps = {
    ...props.innerProps,
    'aria-label': `${kebabCase(props.selectProps.name)}-listbox`,
    id: `${kebabCase(props.selectProps.name)}-listbox`,
    role: 'listbox',
  };

  return <components.MenuList {...props} innerProps={innerProps} />;
};

const CustomOption = (props) => {
  const innerProps = {
    ...props.innerProps,
    'aria-label': `${kebabCase(props.selectProps.name)}-option`,
    'aria-disabled': props.selectProps.isDisabled,
    role: 'option',
  };

  return <components.Option {...props} innerProps={innerProps} />;
};

const CustomInput = (props) => {
  const innerProps = {
    ...props.innerProps,
    'aria-label': `${kebabCase(props.selectProps.name)}`,
    'aria-labelledby': `${kebabCase(props.selectProps.name)}-label`,
  };

  return <components.Input {...props} {...innerProps} />;
};

export class SearchableDropdown extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: props.value,
      isExpanded: false
    };
  }

  // eslint-disable-next-line camelcase
  UNSAFE_componentWillReceiveProps = (nextProps) => {
    this.setState({ value: nextProps.value });
  };

  onChange = (value) => {
    let newValue = value;
    let deletedValue = null;
    let { clearOnSelect, multi, onChange, selfManageValueState } = this.props;

    /*
     * this is a temp fix for react-select value backspace
     * issue.
     * Setting value to null when an option is deselected
     * using the backspace.
     * https://github.com/JedWatson/react-select/pull/773
     */
    if (!multi && Array.isArray(value) && value.length <= 0) {
      newValue = null;
    } else if (multi && value === null) {
      // Fix for https://github.com/JedWatson/react-select/issues/3632
      newValue = [];
    }
    // don't set value in state if creatable is true
    if (!selfManageValueState) {
      this.setState({ value: clearOnSelect ? null : newValue });
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
    if (onChange) {
      onChange(newValue, deletedValue);
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
      defaultValue,
      filterOption,
      isClearable,
      inputRef,
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
      <div className={errorMessage ? 'usa-input-error' : ''}>
        <div className={dropdownClasses} {...dropdownStyling}>
          <label className={labelClasses} htmlFor={name} id={`${kebabCase(name)}-label`}>
            {strongLabel ? <strong>{labelContents}</strong> : labelContents}
          </label>
          {errorMessage && (
            <span className="usa-input-error-message">{errorMessage}</span>
          )}
          <div className="cf-select" role="combobox" aria-expanded={this.state.isExpanded}>
            <SelectComponent
              components={{ Input: CustomInput, MenuList: CustomMenuList, Option: CustomOption }}
              name={name}
              classNamePrefix="cf-select"
              inputId={name}
              options={options}
              defaultOptions={defaultOptions}
              defaultValue={defaultValue}
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
              onMenuOpen={() => this.setState({ isExpanded: true })}
              onMenuClose={() => this.setState({ isExpanded: false })}
              ref={inputRef}
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

CustomMenuList.propTypes = {
  clearValue: PropTypes.func,
  className: PropTypes.string,
  cx: PropTypes.func,
  getStyles: PropTypes.func,
  getValue: PropTypes.func,
  hasValue: PropTypes.bool,
  isMulti: PropTypes.bool,
  isRtl: PropTypes.bool,
  options: PropTypes.arrayOf(PropTypes.object),
  selectOption: PropTypes.func,
  selectProps: PropTypes.any,
  setValue: PropTypes.func,
  children: PropTypes.node,
  theme: PropTypes.object,
  innerRef: PropTypes.oneOfType([
    PropTypes.func,
    PropTypes.shape({ current: PropTypes.elementType })
  ]),
  focusedOption: PropTypes.object,
  innerProps: PropTypes.object
};

CustomInput.propTypes = {
  clearValue: PropTypes.func,
  className: PropTypes.string,
  cx: PropTypes.func,
  getStyles: PropTypes.func,
  getValue: PropTypes.func,
  hasValue: PropTypes.bool,
  isMulti: PropTypes.bool,
  isRtl: PropTypes.bool,
  options: PropTypes.arrayOf(PropTypes.object),
  selectOption: PropTypes.func,
  selectProps: PropTypes.any,
  setValue: PropTypes.func,
  theme: PropTypes.object,
  innerRef: PropTypes.oneOfType([
    PropTypes.func,
    PropTypes.shape({ current: PropTypes.elementType })
  ]),
  isHidden: PropTypes.bool,
  isDisabled: PropTypes.bool,
  form: PropTypes.string,
  innerProps: PropTypes.object
};

CustomOption.propTypes = {
  clearValue: PropTypes.func,
  className: PropTypes.string,
  cx: PropTypes.func,
  getStyles: PropTypes.func,
  getValue: PropTypes.func,
  hasValue: PropTypes.bool,
  isMulti: PropTypes.bool,
  isRtl: PropTypes.bool,
  options: PropTypes.arrayOf(PropTypes.object),
  selectOption: PropTypes.func,
  selectProps: PropTypes.any,
  setValue: PropTypes.func,
  theme: PropTypes.object,
  innerRef: PropTypes.oneOfType([
    PropTypes.func,
    PropTypes.shape({ current: PropTypes.elementType })
  ]),
  isHidden: PropTypes.bool,
  isDisabled: PropTypes.bool,
  isFocused: PropTypes.bool,
  isSelected: PropTypes.bool,
  children: PropTypes.node,
  innerProps: PropTypes.object,
  label: PropTypes.string,
  type: PropTypes.string,
  data: PropTypes.any
};

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
  defaultValue: PropTypes.oneOfType([
    PropTypes.object,
    PropTypes.arrayOf(PropTypes.object),
  ]),
  dropdownStyling: PropTypes.object,
  errorMessage: PropTypes.string,
  filterOption: PropTypes.func,

  /**
   * Pass a ref to the underlying React Select element
   */
  inputRef: PropTypes.oneOfType([
    // Either a function
    PropTypes.func,
    // Or the instance of a DOM native element (see the note about SSR)
    PropTypes.shape({ current: PropTypes.instanceOf(Element) }),
  ]),
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
