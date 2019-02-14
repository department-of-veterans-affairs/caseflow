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
 *   - @tableData {array} the entire data set for the table (required to calculate
 *     the options each column can be filtered on)
 *   - @columnName {string} the name of the column in the table data
 *   - @toggleDropdownFilterVisibility {function} changes the status of the filter
 *     dropdown's visibility, and dispatches an action to change a new value in the
 *     store to capture this information
 *   - @filteredByList {object} the list of filters that have been selected;
 *     this data comes from the store, and is an object where each key is a column name,
 *     which then points to an array of the specific options that column is filtered by
 *   - @updateFilters {function} updates the filteredByList
 *   - @isDropdownFilterOpen {boolean} a property from the store that is updated by
 *     toggleDropdownFilterVisibility, and should receive the specific column name
 *   - @anyFiltersAreSet {boolean} determines whether the "Clear All Filters" option
 *     in the dropdown is enabled
 *   - @customFilterLabels {object} key-value pairs translating the data values to
 *     user readable text
 *   - @label {string} used for the aria-label on the icon,
 *   - @valueName {string} if valueFunction is not defined, cell value will use
 *     valueName to pull that attribute from the rowObject.
 */

class TableFilter extends React.PureComponent {
  filterDropdownOptions = (tableDataByRow, columnName) => {
    let countByColumnName = _.countBy(tableDataByRow, columnName);
    let uniqueOptions = [];
    const filtersForColumn = _.get(this.props.filteredByList, columnName);
    const { customFilterLabels } = this.props;

    for (let key in countByColumnName) { // eslint-disable-line guard-for-in
      let displayText = `<<blank>> (${countByColumnName[key]})`;

      if (key && key !== 'null' && key !== 'undefined') {
        if (customFilterLabels && customFilterLabels[key]) {
          displayText = `${customFilterLabels[key]} (${countByColumnName[key]})`;
        } else {
          displayText = `${_.capitalize(key)} (${countByColumnName[key]})`;
        }

        uniqueOptions.push({
          value: key,
          displayText,
          checked: filtersForColumn ? filtersForColumn.includes(key) : false
        });
      } else {
        uniqueOptions.push({
          value: 'null',
          displayText
        });
      }
    }

    return _.sortBy(uniqueOptions, 'displayText');
  }

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

    filteredByList[columnName] = newFilters;
    this.props.updateFilters(filteredByList);
    this.props.toggleDropdownFilterVisibility(columnName);
  }

  clearFilteredByList = (columnName) => {
    const filterList = this.props.filteredByList;

    filterList[columnName] = [];

    this.props.updateFilters(filterList);
    this.props.toggleDropdownFilterVisibility(columnName);
  }

  render() {
    const {
      tableData,
      columnName,
      toggleDropdownFilterVisibility,
      filteredByList,
      isDropdownFilterOpen,
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
            isDropdownFilterOpen ||
            (filteredByList[columnName] ? filteredByList[columnName].length > 0 : false)}
          handleActivate={() => toggleDropdownFilterVisibility(columnName)} />

        {isDropdownFilterOpen &&
          <QueueDropdownFilter
            clearFilters={() => this.clearFilteredByList(columnName)}
            name={valueName}
            isClearEnabled={anyFiltersAreSet}
            handleClose={() => toggleDropdownFilterVisibility(columnName)}
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

TableFilter.propTypes = {
  enableFilter: PropTypes.bool,
  tableData: PropTypes.array,
  columnName: PropTypes.string,
  anyFiltersAreSet: PropTypes.bool,
  customFilterLabels: PropTypes.object,
  label: PropTypes.string,
  valueName: PropTypes.string,
  toggleDropdownFilterVisibility: PropTypes.func,
  filteredByList: PropTypes.object,
  updateFilters: PropTypes.func,
  isDropdownFilterOpen: PropTypes.bool
};

export default TableFilter;
