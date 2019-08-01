import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

import { css, hover } from 'glamor';
import FilterIcon from './FilterIcon';
import QueueDropdownFilter from '../queue/QueueDropdownFilter';
import FilterOption from './FilterOption';

/**
 * This component can be used to implement filtering for a table column.
 * The required props are:
 * - @column {array[string]} array of objects that define the properties
 *   of the column. Possible attributes for each column include:
 *   - @enableFilter {boolean} whether filtering is turned on for each column
 *   - @enableFilterTextTransform {boolean} when true, filter text that gets displayed
 *     is automatically capitalized. default is true.
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
 */

class TableFilter extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = { open: false };
  }

  transformColumnValue = (columnValue) => {
    const { valueTransform } = this.props;

    return valueTransform ? valueTransform(columnValue) : columnValue;
  }

  filterDropdownOptions = (tableDataByRow, columnName) => {
    const { customFilterLabels, enableFilterTextTransform } = this.props;
    const countByColumnName = _.countBy(
      tableDataByRow,
      (row) => this.transformColumnValue(row[columnName])
    );
    const uniqueOptions = [];
    const filtersForColumn = _.get(this.props.filteredByList, columnName);

    for (let key in countByColumnName) { // eslint-disable-line guard-for-in
      let displayText = `<<blank>> (${countByColumnName[key]})`;
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

  toggleDropdown = () => this.setState({ open: !this.state.open });

  hideDropdown = () => this.setState({ open: false });

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

  clearFilteredByList = (columnName) => {
    let filterList = { ...this.props.filteredByList };

    delete filterList[columnName];

    this.props.updateFilters(filterList);
    this.hideDropdown();
  }

  render() {
    const {
      tableData,
      columnName,
      filteredByList,
      anyFiltersAreSet,
      label,
      valueName,
      getFilterValues
    } = this.props;

    const iconStyle = css({
      display: 'table-cell',
      paddingLeft: '1rem',
      paddingTop: '0.3rem',
      verticalAlign: 'middle'
    }, hover({ cursor: 'pointer' }));

    const filterOptions = tableData && columnName ?
      this.filterDropdownOptions(tableData, columnName) :
      // Keeping the historical prop `getFilterValues` for backwards compatibility,
      // will remove this once all apps are using this new component.
      getFilterValues;

    return (
      <span {...iconStyle}>
        <FilterIcon
          label={label}
          getRef={this.props.getFilterIconRef}
          selected={
            this.state.open ||
            (filteredByList[columnName] ? filteredByList[columnName].length > 0 : false)}
          handleActivate={this.toggleDropdown} />

        {this.state.open &&
          <QueueDropdownFilter
            clearFilters={() => this.clearFilteredByList(columnName)}
            name={valueName}
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
  tableData: PropTypes.array,
  columnName: PropTypes.string,
  anyFiltersAreSet: PropTypes.bool,
  customFilterLabels: PropTypes.object,
  label: PropTypes.string,
  valueName: PropTypes.string,
  valueTransform: PropTypes.func,
  filteredByList: PropTypes.object,
  updateFilters: PropTypes.func
};

export default TableFilter;
