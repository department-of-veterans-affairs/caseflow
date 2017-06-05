import React from 'react';
import PropTypes from 'prop-types';
import { closeIcon } from './RenderFunctions';
import Button from './Button';
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

    let sizeClasses = () => {
      if (size==="big") {
        sizeClasses = ['usa-search', 'usa-search-big']
      }
      else if (size==="small")
        sizeClasses = ['usa-search', 'usa-search-small']
      else {
        sizeClasses = ['usa-search', 'usa-search-medium']
      }
      return sizeClasses.join(" ");
    }

    // This returns the magnifying glass for small sized searchbars
    let buttonClassNames = () => {
      if (size==="small") {
        return 'usa-sr-only'
      }
      else {
        return 'usa-search-submit-text'
      }
    }

    let label = () => {
      if (size==="big") {
        label = ('usa-search-big')
      }
      else if (size==="medium") {
        label = ('usa-search-medium')
      }
      else {
        label = 'usa-search-small'
      }
      return label;
    }

    const inputClassName = onClearSearch ? 'cf-search-input-with-close' : '';

    return <span className={sizeClasses()} role="search">
      <label className={title ? label() : 'usa-sr-only'} htmlFor={id}>
        {title ? title : 'Search small'}
      </label>
      <input
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
        <span className={buttonClassNames()}>Search</span>
      </Button>
    </span>;
  }
}

SearchBar.propTypes = {
  id: PropTypes.string.isRequired,
  title: PropTypes.string,
  onChange: PropTypes.func,
  onClick: PropTypes.func,
  onClearSearch: PropTypes.func,
  loading: PropTypes.bool,
  value: PropTypes.string
};
