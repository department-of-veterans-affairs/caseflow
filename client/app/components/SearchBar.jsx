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
      classNames,
      id,
      onClick,
      value,
      onClearSearch,
      loading,
      title
    } = this.props;

    let getSrOnlyClassName = () => {

      // if (/usa-search-(big|medium)/.test(this.props.classNames)) {
      //   return '';
      // }

      // return 'usa-sr-only';

      if(/usa-search-small/.test(this.props.classNames)) {
        return classNames.push('usa-sr-only')
      }

    };

    const inputClassName = onClearSearch ? 'cf-search-input-with-close' : '';

    return <span className={this.props.classNames} role="search">
      <label className={this.props.classNames} htmlFor={id}>{title}</label>
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
        <span className={getSrOnlyClassName()}>Search</span>
      </Button>
    </span>;
  }
}

SearchBar.defaultProps = {
  classNames: ['usa-search']
};

SearchBar.propTypes = {
  id: PropTypes.string.isRequired,
  title: PropTypes.string,
  onChange: PropTypes.func,
  onClick: PropTypes.func,
  onClearSearch: PropTypes.func,
  loading: PropTypes.bool,
  value: PropTypes.string
};
