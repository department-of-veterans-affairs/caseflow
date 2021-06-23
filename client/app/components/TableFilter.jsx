import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import { css, hover } from 'glamor';
import COPY from '../../COPY';
import FilterIcon from './FilterIcon';
import QueueDropdownFilter from '../queue/QueueDropdownFilter';
import FilterOption from './FilterOption';

const iconStyle = css(
  {
    display: 'table-cell',
    paddingLeft: '1rem',
    paddingTop: '0.3rem',
    verticalAlign: 'middle'
  },
  hover({ cursor: 'pointer' })
);

/**
 * This component can be used to implement filtering for a table column.
 * The required props are:
 * - @column {array[string]} array of objects that define the properties
 *   of the column. Possible attributes for each column include:
 *   - @enableFilter {boolean} whether filtering is turned on for each column
 *   - @enableFilterTextTransform {boolean} when true, filter text that gets displayed
 *     is automatically capitalized. default is true.
 *   - @getFilterIconRef {function}
 *   - @getFilterValues {function} DEPRECATED
 *   - @tableData {array} the entire data set for the table (required to calculate
 *     the options each column can be filtered on)
 *   - @columnName {string} the name of the column in the table data
 *   - @filteredByList {object} the list of filters that have been selected;
 *     this data comes from the store, and is an object where each key is a column name,
 *     which then points to an array of the specific options that column is filtered by
 *   - @updateFilters {function} updates the filteredByList
 *   - @anyFiltersAreSet {boolean} determines whether the "Clear All Filters" option
 *     in the dropdown is enabled
 *   - @customFilterLabels {object} key-value pairs translating the data values to
 *     user readable text
 *   - @label {string} used for the aria-label on the icon,
 *   - @valueName {string} used as the name for the dropdown filter.
 *   - @valueTransform {function(any, any)} function that takes the value of the
 *     column, and transforms it into a string. The row is passed in as a second
 *     argument.
 */

class TableFilter extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = { open: false };
  }

  transformColumnValue = (columnValue, row) => {
    const { valueTransform } = this.props;

    return valueTransform ? valueTransform(columnValue, row) : columnValue;
  }

  filterDropdownOptions = (tableDataByRow, columnName) => {
    const { customFilterLabels, enableFilterTextTransform, filterOptionsFromApi } = this.props;
    const filtersForColumn = _.get(this.props.filteredByList, columnName);

    if (filterOptionsFromApi && filterOptionsFromApi.length) {
      filterOptionsFromApi.forEach((option) => {
        option.checked = filtersForColumn ? filtersForColumn.includes(option.value) : false;
      });

      return _.sortBy(filterOptionsFromApi, 'displayText');
    }

    const countByColumnName = _.countBy(
      tableDataByRow,
      (row) => this.transformColumnValue(_.get(row, columnName), row)
    );
    const uniqueOptions = [];

    for (let key in countByColumnName) { // eslint-disable-line guard-for-in
      let displayText = `${COPY.NULL_FILTER_LABEL} (${countByColumnName[key]})`;
      let keyValue = 'null';

      if (key && key !== 'null' && key !== 'undefined') {
        if (customFilterLabels && customFilterLabels[key]) {
          displayText = `${customFilterLabels[key]} (${countByColumnName[key]})`;
        } else {
          const displayKey = enableFilterTextTransform ? _.capitalize(key) : key;

          displayText = `${displayKey} (${countByColumnName[key]})`;
        }

        keyValue = key;
      }

      uniqueOptions.push({
        value: keyValue,
        displayText,
        checked: filtersForColumn ? filtersForColumn.includes(keyValue) : false
      });
    }

    return _.sortBy(uniqueOptions, 'displayText');
  }

  isFilterOpen = () => {
    const { columnName, filteredByList } = this.props;

    return this.state.open || (filteredByList[columnName] || []).length > 0;
  }

  toggleDropdown = () => this.setState({ open: !this.state.open });

  hideDropdown = () => this.setState({ open: false });

  // Callback when a filter gets selected.
  //
  // Adds the text (string) for a filtered value to an internal list. The list holds all the
  // values to filter by.
  updateSelectedFilter = (value, columnName) => {
    const { filteredByList } = this.props;
    const filtersForColumn = _.get(filteredByList, String(columnName));
    let newFilters = [];

    if (filtersForColumn) {
      if (filtersForColumn.includes(value)) {
        newFilters = _.pull(filtersForColumn, value);
      } else {
        newFilters = filtersForColumn.concat([value]);
      }
    } else {
      newFilters = newFilters.concat([value]);
    }

    // Clone here so that we are sending a new list to updateFilters() instead of the same list that has already been
    // modified. If we send the existing list to updateFilters() we do not trigger a re-render.
    let newFilteredByList = _.clone(filteredByList);

    newFilteredByList[columnName] = newFilters;
    this.props.updateFilters(newFilteredByList);
    this.toggleDropdown();
  }

  clearFilteredByList = () => {
    let { filteredByList, columnName } = this.props;
    let filterList = { ...filteredByList };

    delete filterList[columnName];

    this.props.updateFilters(filterList);
    this.hideDropdown();
  }

  filterIconAriaLabel = () => {
    const {
      filteredByList,
      columnName,
      label
    } = this.props;

    const selectedOptions = filteredByList[columnName] || '';

    return selectedOptions.length ? sprintf('%s. Filtering by %s', label, selectedOptions) : label;
  }

  render() {
    const {
      tableData,
      columnName,
      anyFiltersAreSet,
      valueName,
      getFilterValues
    } = this.props;

    const filterOptions = tableData && columnName ?
      this.filterDropdownOptions(tableData, columnName) :
      // Keeping the historical prop `getFilterValues` for backwards compatibility,
      // will remove this once all apps are using this new component.
      //
      // WARNING: If you use getFilterValues, it will cause some of the options to
      // not display correctly when they are checked.
      getFilterValues;

    return (
      <span {...iconStyle}>
        <FilterIcon
          aria-label={this.filterIconAriaLabel()}
          label={this.filterIconAriaLabel()}
          getRef={this.props.getFilterIconRef}
          selected={this.isFilterOpen()}
          handleActivate={this.toggleDropdown} />

        {this.state.open &&
          <QueueDropdownFilter
            clearFilters={this.clearFilteredByList}
            name={valueName || columnName}
            isClearEnabled={anyFiltersAreSet}
            handleClose={this.toggleDropdown}
            addClearFiltersRow>
            <FilterOption
              options={filterOptions}
              setSelectedValue={(value) => this.updateSelectedFilter(value, columnName)} />
          </QueueDropdownFilter>
        }
      </span>
    );
  }
}

TableFilter.defaultProps = {
  enableFilterTextTransform: true
};

TableFilter.propTypes = {
  enableFilter: PropTypes.bool,
  enableFilterTextTransform: PropTypes.bool,
  getFilterIconRef: PropTypes.func,
  getFilterValues: PropTypes.func,
  tableData: PropTypes.array,
  columnName: PropTypes.string,
  anyFiltersAreSet: PropTypes.bool,
  customFilterLabels: PropTypes.object,
  label: PropTypes.string,
  valueName: PropTypes.string,
  valueTransform: PropTypes.func,
  filteredByList: PropTypes.object,
  updateFilters: PropTypes.func,
  filterOptionsFromApi: PropTypes.array
};

export default TableFilter;
