import React from 'react';
import PropTypes from 'prop-types';
import { closeIcon } from './RenderFunctions';
import Button from './Button';
import classnames from 'classnames';
import Analytics from '../util/AnalyticsUtil';
import _ from 'lodash';

export default class SearchBar extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  }

  // A "search" event occurs when a user finishes typing
  // a search query. This is 500ms after the last character
  // typed or when focus is lost
  onSearch = () => {
    if (this.props.value && this.props.analyticsCategory) {
      Analytics.event(this.props.analyticsCategory, 'search', '');

      if (this.props.recordSearch) {
        this.props.recordSearch(this.props.value);
      }
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

  render() {
    let {
      id,
      value,
      loading,
      onClearSearch,
      size,
      title
    } = this.props;

    const sizeClasses = classnames('usa-search', {
      'usa-search-big': size === 'big',
      'usa-search-small': size === 'small'
    });

    const buttonClassNames = classnames({
      'usa-sr-only': size === 'small'
    });

    const label = classnames({
      'usa-search-big': size === 'big',
      'usa-search-small': size === 'small'
    });

    return <span className={sizeClasses} role="search">
      <label className={title ? label : 'usa-sr-only'} htmlFor={id}>
        {title || 'Search small'}
      </label>
      <input
        className='cf-search-input-with-close'
        id={id}
        onChange={this.onChange}
        onBlur={this.onBlur}
        type="search"
        name="search"
        value={value}/>
      {_.size(value) > 0 &&
        <Button
          ariaLabel="clear search"
          name="clear search"
          classNames={['cf-pdf-button cf-search-close-icon']}
          onClick={onClearSearch}>
          {closeIcon()}
        </Button>}
      <Button name={`search-${id}`} type="submit" loading={loading}>
        <span className={buttonClassNames}>Search</span>
      </Button>
    </span>;
  }
}

SearchBar.propTypes = {
  id: PropTypes.string.isRequired,
  title: PropTypes.string,
  size: PropTypes.string,
  onChange: PropTypes.func,
  onClick: PropTypes.func,
  onClearSearch: PropTypes.func,
  recordSearch: PropTypes.func,
  loading: PropTypes.bool,
  value: PropTypes.string,
  analyticsCategory: PropTypes.string
};

