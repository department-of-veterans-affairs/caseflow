import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import Button from '../components/Button';

export default class FilterRibbon extends React.PureComponent {
  render() {

    const filteredCategories = this.props.filteredByList ? this.props.filteredByList.join(', ') : '';

    const className = classNames('filter-list-message', {
      hidden: !filteredCategories.length
    });

    return <p className={className}>Filtering by: {filteredCategories}<Button
      id="clear-filters"
      name="clear-filters"
      classNames={['cf-btn-link']}
      onClick={this.props.clearAllFilters}>
      &nbsp;&nbsp;Clear all filters.</Button></p>;
  }
}

FilterRibbon.propTypes = {
  filteredByList: PropTypes.array.isRequired,
  clearAllFilters: PropTypes.func.isRequired
};
