import React, { PropTypes } from 'react';
import { closeIcon } from './RenderFunctions';
import Button from './Button';

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

    return <span className="usa-search usa-search-small" role="search">
      <label className="usa-sr-only" htmlFor={id}>Search small</label>
      <input
        className={inputClassName}
        id={id}
        onChange={this.onChange}
        type="search"
        name="search"
        value={value}/>
      {onClearSearch &&
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

SearchBar.propTypes = {
  id: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  onClick: PropTypes.func,
  onClearSearch: PropTypes.func,
  value: PropTypes.string
};
