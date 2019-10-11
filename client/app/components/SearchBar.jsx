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
  }

  // A "search" event occurs when a user finishes typing
  // a search query. This is 500ms after the last character
  // typed or when focus is lost.
  onSearch = () => {
    if (this.props.value && this.props.recordSearch) {
      this.props.recordSearch(this.props.value);
    }
  }

  onSubmit = () => {
    if (this.props.onSubmit) {
      this.props.onSubmit(this.props.value);
    }
  }

  handleKeyPress = (event) => {
    if (event.key === 'Enter') {
      this.onSubmit();
    }
  }

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
  }

  setInputRef = (node) => this.input = node

  setInputFocus = () => this.input.focus()
  releaseInputFocus = () => this.input.blur();

  clearInput = () => this.input.value = '';

  getInternalField = (spinnerColor = COLORS.WHITE) => {
    if (this.props.loading) {
      return <div className="search-text-spinner">
        { loadingSymbolHtml('', '25px', spinnerColor) }
      </div>;
    }

    return <input
      id="search-internal-text"
      type="text"
      value={this.props.internalText}
      onClick={this.setInputFocus}
      className="cf-search-internal-text"
      readOnly />;
  }

  render() {
    let {
      id,
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
      spinnerColor
    } = this.props;

    id = id || uuid.v4();

    const hasInternalText = !_.isUndefined(internalText);

    const searchTypeClasses = classnames('usa-search', {
      'usa-search-big': size === 'big',
      'usa-search-small': size === 'small',
      'cf-search-ahead': isSearchAhead,
      'cf-has-internal-text': hasInternalText
    });

    const buttonClassNames = classnames({
      'usa-sr-only': size === 'small'
    });

    const label = classnames({
      'usa-search-big': size === 'big',
      'usa-search-small': size === 'small'
    });

    const searchClasses = classnames('cf-search-input-with-close', {
      'cf-search-with-internal-text': hasInternalText
    });

    return <span className={searchTypeClasses} role="search">
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
        onKeyPress={submitUsingEnterKey && !searchDisabled ? this.handleKeyPress : this.props.onKeyPress}
        placeholder={placeholder}
        value={value} />
      { hasInternalText &&
      <div>
        <label className="usa-sr-only" htmlFor="search-internal-text">
          Search Result Count
        </label>
        { this.getInternalField(spinnerColor) }
      </div>}
      {_.size(value) > 0 &&
        <Button
          ariaLabel="clear search"
          name="clear search"
          classNames={['cf-pdf-button cf-search-close-icon']}
          onClick={onClearSearch}>
          {closeIcon()}
        </Button>}
      { !isSearchAhead && <Button name={`search-${id}`}
        disabled={searchDisabled}
        onClick={onSubmit ? this.onSubmit : null} on type="submit" loading={loading}>
        <span className={buttonClassNames}>Search</span>
      </Button> }
    </span>;
  }
}

SearchBar.propTypes = {
  id: PropTypes.string,
  title: PropTypes.string,
  size: PropTypes.string,
  onChange: PropTypes.func,
  onKeyPress: PropTypes.func,
  onClick: PropTypes.func,
  onClearSearch: PropTypes.func,
  recordSearch: PropTypes.func,
  isSearchAhead: PropTypes.bool,
  loading: PropTypes.bool,
  value: PropTypes.string,
  analyticsCategory: PropTypes.string,
  onSubmit: PropTypes.func,
  searchDisabled: PropTypes.bool,
  submitUsingEnterKey: PropTypes.bool,
  internalText: PropTypes.string,
  spinnerColor: PropTypes.string,
  placeholder: PropTypes.string
};
