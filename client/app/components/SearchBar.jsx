import React from 'react';
import PropTypes from 'prop-types';
import { closeIcon } from './RenderFunctions';
import Button from './Button';
import classnames from 'classnames';
import _ from 'lodash';

export default class SearchBar extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  }

  render() {
    let {
      id,
      onClick,
      value,
      onClearSearch,
      loading,
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

    const inputClassName = onClearSearch ? 'cf-search-input-with-close' : '';

    return <span className={sizeClasses} role="search">
      <label className={title ? label : 'usa-sr-only'} htmlFor={id}>
        {title || 'Search small'}
      </label>
      <input
        className={inputClassName}
        id={id}
        onChange={this.onChange}
        type="search"
        name="search"
        value={value}/>
      {onClearSearch && _.size(value) > 0 &&
        <Button
          ariaLabel="clear search"
          name="clear search"
          classNames={['cf-pdf-button cf-search-close-icon']}
          onClick={onClearSearch}>
          {closeIcon()}
        </Button>}
      <Button name={`search-${id}`} onClick={onClick} type="submit" loading={loading}>
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
  loading: PropTypes.bool,
  value: PropTypes.string
};
