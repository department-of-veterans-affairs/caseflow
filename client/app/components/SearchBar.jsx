import React from 'react';
import PropTypes from 'prop-types';
import { closeIcon, loadingSymbolHtml } from './RenderFunctions';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import Button from './Button';
import classnames from 'classnames';
import _ from 'lodash';
import uuid from 'uuid';

export default class SearchBar extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  };

  onSearch = () => {
    if (this.props.value && this.props.recordSearch) {
      this.props.recordSearch(this.props.value);
    }
  };

  onSubmit = () => {
    if (this.props.onSubmit) {
      this.props.onSubmit(this.props.value);
    }
  };

  handleKeyPress = (event) => {
    if (event.key === 'Enter') {
      this.onSubmit();
    }
  };

  clearSearchCallback() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
      this.searchTimeout = null;

      return true;
    }
  }

  /* eslint-disable camelcase */
  UNSAFE_componentWillReceiveProps(nextProps) {
    if (this.props.value !== nextProps.value) {
      this.clearSearchCallback();

      this.searchTimeout = setTimeout(() => {
        this.onSearch();
        this.searchTimeout = null;
      }, 500);
    }
  }
  /* eslint-enable camelcase */

  onBlur = () => {
    if (this.clearSearchCallback()) {
      this.onSearch();
    }
  };

  setInputRef = (node) => (this.input = node);

  setInputFocus = () => this.input.focus();
  releaseInputFocus = () => this.input.blur();

  clearInput = () => (this.input.value = '');

  getInternalField = (spinnerColor) => {
    if (this.props.loading) {
      return (
        <div className="search-text-spinner">
          {loadingSymbolHtml('', '25px', spinnerColor)}
        </div>
      );
    }

    return (
      <input
        id="search-internal-text"
        type="text"
        value={this.props.internalText}
        onClick={this.setInputFocus}
        className="cf-search-internal-text"
        readOnly
        {...this.props.internalTextInputProps}
      />
    );
  };

  render() {
    const {
      id = uuid.v4(),
      inputProps,
      value,
      loading,
      onClearSearch,
      isSearchAhead,
      size,
      title,
      onSubmit,
      searchDisabled,
      submitUsingEnterKey,
      placeholder,
      internalText,
      spinnerColor,
    } = this.props;

    const hasInternalText = !_.isUndefined(internalText);

    const searchTypeClasses = classnames('usa-search', {
      'usa-search-big': size === 'big',
      'usa-search-small': size === 'small',
      'cf-search-ahead': isSearchAhead,
      'cf-has-internal-text': hasInternalText,
    });

    const buttonClassNames = classnames({
      'usa-sr-only': size === 'small',
    });

    const label = classnames({
      'usa-search-big': size === 'big',
      'usa-search-small': size === 'small',
    });

    const searchClasses = classnames('cf-search-input-with-close', {
      'cf-search-with-internal-text': hasInternalText,
    });

    return (
      <span className={searchTypeClasses} role="search">
        <label className={title ? label : 'usa-sr-only'} htmlFor={id}>
          {title || 'Search'}
        </label>
        <input
          ref={this.setInputRef}
          className={searchClasses}
          id={id}
          onChange={this.onChange}
          onBlur={this.onBlur}
          type="search"
          name="search"
          onKeyPress={
            submitUsingEnterKey && !searchDisabled ?
              this.handleKeyPress :
              this.props.onKeyPress
          }
          placeholder={placeholder}
          value={value}
          {...inputProps}
        />
        {hasInternalText && (
          <div>
            <label className="usa-sr-only" htmlFor="search-internal-text">
              Search Result Count
            </label>
            {this.getInternalField(spinnerColor)}
          </div>
        )}
        {_.size(value) > 0 && (
          <Button
            ariaLabel="clear search"
            name="clear search"
            classNames={['cf-pdf-button cf-search-close-icon']}
            onClick={onClearSearch}
          >
            {closeIcon()}
          </Button>
        )}
        {!isSearchAhead && (
          <Button
            name={`search-${id}`}
            disabled={searchDisabled}
            onClick={onSubmit ? this.onSubmit : null}
            on
            type="submit"
            loading={loading}
          >
            <span className={buttonClassNames}>Search</span>
          </Button>
        )}
      </span>
    );
  }
}

SearchBar.defaultProps = {
  spinnerColor: COLORS.WHITE,
};

SearchBar.propTypes = {

  /**
   * Id of the `input` element
   */
  id: PropTypes.string,

  /**
   * Props that will be passed along to the `input` element
   */
  inputProps: PropTypes.object,

  /**
   * Label to display above the search bar, defaults to "Search"
   */
  title: PropTypes.string,

  /**
   * The size of the search bar, "big" | "small"
   */
  size: PropTypes.string,

  /**
   * Callback fired when value is changed
   *
   * @param {string} value The current value of the component
   */
  onChange: PropTypes.func,
  onKeyPress: PropTypes.func,

  /**
   * Callback fired when the "x" button is clicked
   */
  onClearSearch: PropTypes.func,

  /**
   * Callback fired when a user finishes typing a search query, 500ms after the last character typed or focus is lost.
   *
   * @param {string} value The current value of the component
   */
  recordSearch: PropTypes.func,

  /**
   * Whether or not to show a search button. Wrapping parent must have class "cf-search-ahead-parent"
   */
  isSearchAhead: PropTypes.bool,

  /**
   * Whether or not a search is being performed. Will disable the search button and show a loading icon if true
   */
  loading: PropTypes.bool,

  /**
   * The value of the `input` element
   */
  value: PropTypes.string,

  /**
   * Callback fired when search is initiated, either but pressing search or enter if `submitUsingEnterKey` is true
   *
   * @param {string} value The current value of the component
   */
  onSubmit: PropTypes.func,

  /**
   * Whether or not to disable the search button
   */
  searchDisabled: PropTypes.bool,

  /**
   * Whether or not to allow users to initiate a search by hitting the "Enter" key
   */
  submitUsingEnterKey: PropTypes.bool,

  /**
   * Text to show on the inside of the search bar, justified right. Only supported with size 'small'
   */
  internalText: PropTypes.string,

  /**
   * Props that will be passed along to the `input` element that is a child of the internal text element
   */
  internalTextInputProps: PropTypes.object,

  /**
   * Color of the loading icon to display while loading
   */
  spinnerColor: PropTypes.string,

  /**
   * Text to display when there is no search term in the `input`
   */
  placeholder: PropTypes.string,
};
