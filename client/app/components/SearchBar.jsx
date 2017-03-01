import React, { PropTypes } from 'react';

export default class SearchBar extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  }

  render() {
    let {
      id,
      onClick,
      value
    } = this.props;

    return <span className="usa-search usa-search-small" role="search">
      <label className="usa-sr-only" htmlFor={id}>Search small</label>
      <input id={id} onChange={this.onChange} type="search" name="search" value={value}/>
      <button onClick={onClick} type="submit">
        <span className="usa-sr-only">Search</span>
      </button>
    </span>;
  }
}

SearchBar.propTypes = {
  id: PropTypes.string,
  onChange: PropTypes.func,
  onClick: PropTypes.func,
  value: PropTypes.string
};
