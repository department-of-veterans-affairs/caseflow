import React from 'react';
import PropTypes from 'prop-types';
import { closeIcon } from './RenderFunctions';
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

  componentWillReceiveProps(nextProps) {
    if (this.props.value !== nextProps.value) {
      this.clearSearchCallback();

      this.searchTimeout = setTimeout(() => {
        this.onSearch();
        this.searchTimeout = null;
      }, 500);
    }
  }

  onBlur = () => {
    if (this.clearSearchCallback()) {
      this.onSearch();
    }
  }

  componentDidMount = () => {
    if (this.props.onClearSearch) {
      this.props.onClearSearch();
    }
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
      submitUsingEnterKey,
      placeholder
    } = this.props;

    id = id || uuid.v4();

    const searchTypeClasses = classnames('usa-search', {
      'usa-search-big': size === 'big',
      'usa-search-small': size === 'small',
      'cf-search-ahead': isSearchAhead
    });

    const buttonClassNames = classnames({
      'usa-sr-only': size === 'small'
    });

    const label = classnames({
      'usa-search-big': size === 'big',
      'usa-search-small': size === 'small'
    });

    return <span className={searchTypeClasses} role="search">
      <label className={title ? label : 'usa-sr-only'} htmlFor={id}>
        {title || 'Search small'}
      </label>
      <input
        className="cf-search-input-with-close"
        id={id}
        onChange={this.onChange}
        onBlur={this.onBlur}
        type="search"
        name="search"
        onKeyPress={submitUsingEnterKey ? this.handleKeyPress : null}
        placeholder={placeholder}
        value={value}/>
      {_.size(value) > 0 &&
        <Button
          ariaLabel="clear search"
          name="clear search"
          classNames={['cf-pdf-button cf-search-close-icon']}
          onClick={onClearSearch}>
          {closeIcon()}
        </Button>}
      { !isSearchAhead && <Button name={`search-${id}`}
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
  onClick: PropTypes.func,
  onClearSearch: PropTypes.func,
  recordSearch: PropTypes.func,
  loading: PropTypes.bool,
  value: PropTypes.string,
  analyticsCategory: PropTypes.string,
  onSubmit: PropTypes.func,
  submitUsingEnterKey: PropTypes.bool
};
