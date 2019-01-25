import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

import { css, hover } from 'glamor';
import FilterIcon from './FilterIcon';
import DropdownFilter from './DropdownFilter';
import ListItemPicker from './ListItemPicker';
import FilterOption from './FilterOption';

/**
 * This component can be used to implement filtering for a table column.
 * The required props are:
 * - @column {array[string]} array of objects that define the properties
 *   of the column. Possible attributes for each column include:
 *   - @valueName {string} if valueFunction is not defined, cell value will use
 *     valueName to pull that attribute from the rowObject.
 */

class TableFilter extends React.PureComponent {
  constructor(props) {
    super(props);

    // this.state = {
    //   filteredByList: []
    // };
  }

  filterDropdownOptions = (tableDataByRow, columnName) => {
    let countByFilterName = _.countBy(tableDataByRow, columnName);
    let uniqueOptions = [];
    const filtersForColumn = _.get(this.props.column.filteredByList, columnName);

    for (let key in countByFilterName) {
      if (key && key !== 'null' && key !== 'undefined') {
        uniqueOptions.push({
          value: key,
          displayText: `${key} (${countByFilterName[key]})`,
          checked: filtersForColumn ? filtersForColumn.includes(key) : false
        });
      } else {
        uniqueOptions.push({
          value: 'null',
          displayText: `<<blank>> (${countByFilterName[key]})`
        });
      }
    }

    return _.sortBy(uniqueOptions, 'displayText');
  }

  // filterTableData = (dataToFilter, filterName, value) => {
  //   let filteredData = {};

  //   for (let key in dataToFilter) {
  //     if (String(_.get(dataToFilter[key], filterName)) === String(value)) {
  //       filteredData[key] = dataToFilter[key];
  //     }
  //   }

  //   return filteredData;
  // }

  updateSelectedFilter = (value, filterName) => {
    const oldList = this.props.column.filteredByList;
    const filtersForColumn = _.get(oldList, filterName);
    let newList = {};
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

    // const filtersForColumn = this.state.filteredByList;

    // if (filtersForColumn.includes(value)) {
    //   this.unsetSelectedFilter(value, filterName);
    // } else {
    //   this.setSelectedFilter(value, filterName);
    // }

    newList = _.set(oldList, filterName, newFilters);
    this.props.column.updateFilters(newList);

    // For some reason when filters are removed a render doesn't automatically happen
    this.forceUpdate();
  }

  // updateTableData = (value, filterName) => {
  //   const filteredData = this.filterTableData(this.props.column.tableData, filterName, value);
  //   // this.props.column.receiveUpdatedData(filteredData);
  // }

  // setSelectedFilter = (value, filterName) => {
  //   this.updateTableData(value, filterName);
  //   this.setState({
  //     filteredByList: this.state.filteredByList.concat([value])
  //   });
  // }

  // unsetSelectedFilter = (value, filterName) => {
  //   this.updateTableData(value, filterName);
  //   this.setState({
  //     filteredByList: _.pull(this.state.filteredByList, value)
  //   });

  //   this.forceUpdate();
  // }

  clearFilteredByList = (filterName) => {
    // this.updateTableData(value, filterName);
    // this.setState({
    //   filteredByList: []
    // });
    const oldList = this.props.column.filteredByList;
    let newList = _.set(oldList, filterName, []);

    this.props.column.updateFilters(newList);

    // For some reason when filters are removed a render doesn't automatically happen
    this.forceUpdate();
  }

  render() {
    const {
      column
    } = this.props;

    const iconStyle = css({
      display: 'table-cell',
      paddingLeft: '1rem',
      paddingTop: '0.3rem',
      verticalAlign: 'middle'
    }, hover({ cursor: 'pointer' }));

    const filterOptions = column.tableData && column.columnName ?
      this.filterDropdownOptions(column.tableData, column.columnName) :
      // Keeping the historical prop `getFilterValues` for backwards compatibility,
      // will remove this once all apps are using this new component.
      column.getFilterValues;

    return (
      <span {...iconStyle}>
        <FilterIcon
          label={column.label}
          idPrefix={column.valueName}
          getRef={column.getFilterIconRef}
          selected={column.isDropdownFilterOpen || column.anyFiltersAreSet}
          handleActivate={column.toggleDropdownFilterVisibility} />

        {column.isDropdownFilterOpen &&
          <DropdownFilter
            clearFilters={() => this.clearFilteredByList(column.columnName)}
            name={column.valueName}
            isClearEnabled={column.anyFiltersAreSet}
            handleClose={column.toggleDropdownFilterVisibility}
            addClearFiltersRow>
            <FilterOption
              options={filterOptions}
              setSelectedValue={(value) => this.updateSelectedFilter(value, column.columnName)} />
          </DropdownFilter>
        }
      </span>
    );
  }
}

TableFilter.propTypes = {
  column: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.object),
    PropTypes.func]).isRequired
};

export default TableFilter;
