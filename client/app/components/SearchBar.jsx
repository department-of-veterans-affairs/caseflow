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
      onClearSearch
    } = this.props;

    const inputClassName = onClearSearch ? 'cf-search-input-with-close' : '';

    return <span className={this.props.classNames} role="search">
      <label className="usa-sr-only" htmlFor={id}>Search small</label>
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
      <button onClick={onClick} type="submit">
        <span className="usa-sr-only">Search</span>
      </button>
    </span>;
  }
}

SearchBar.defaultProps = {
  classNames: "usa-search usa-search-small"
};

SearchBar.propTypes = {
  id: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  onClick: PropTypes.func,
  onClearSearch: PropTypes.func,
  value: PropTypes.string
};
