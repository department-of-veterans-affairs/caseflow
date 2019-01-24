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

    this.state = {
      filteredByList: []
    };
  }

  filterDropdownOptions = (tableDataByRow, columnName) => {
    let countByFilterName = _.countBy(tableDataByRow, columnName);
    let uniqueOptions = [];

    for (let key in countByFilterName) {
      if (key && key !== 'null' && key !== 'undefined') {
        uniqueOptions.push({
          value: key,
          displayText: `${key} (${countByFilterName[key]})`,
          checked: this.state.filteredByList.includes(key)
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

  filterTableData = (dataToFilter, filterName, value) => {
    let filteredData = {};

    for (let key in dataToFilter) {
      if (String(_.get(dataToFilter[key], filterName)) === String(value)) {
        filteredData[key] = dataToFilter[key];
      }
    }

    return filteredData;
  }

  updateSelectedFilter = (value, filterName) => {
    if (this.state.filteredByList.includes(value)) {
      unsetSelectedFilter(value, filterName);
    } else {
      setSelectedFilter(value, filterName);
    }
  }

  setSelectedFilter = (value, filterName) => {
    const filteredData = this.filterTableData(this.props.column.tableData, filterName, value);
    // this.props.onReceiveHearingSchedule(filteredData);
    this.setState({
      filteredByList: this.state.filteredByList.concat([value])
    });
    // this.props.column.toggleDropdownFilterVisibility();
  }

  unsetSelectedFilter = (value, filterName) => {
    const newState = _.pull(this.state.filteredByList, value);

    this.setState({
      filteredByList: newState
    });
  }

  clearFilteredByList = () => {
    this.setState({
      filteredByList: []
    });
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
            clearFilters={this.clearFilteredByList}
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
