import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';
import { css, hover } from 'glamor';
import _ from 'lodash';

import Tooltip from '../components/Tooltip';
import { DoubleArrow } from '../components/RenderFunctions';
import TableFilter from '../components/TableFilter';
import FilterSummary from '../components/FilterSummary';
import Pagination from '../components/Pagination';
import {
  COLORS,
  LOGO_COLORS
} from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import LoadingScreen from '../components/LoadingScreen';
import { tasksWithAppealsFromRawTasks } from './utils';
import QUEUE_CONFIG from '../../constants/QUEUE_CONFIG.json';

/**
 * This component can be used to easily build tables.
 * The required props are:
 * - @columns {array[string]} array of objects that define the properties
 *   of the columns. Possible attributes for each column include:
 *   - @header {string|component} header cell value for the column
 *   - @align {sting} alignment of the column ("left", "right", or "center")
 *   - @valueFunction {function(rowObject)} function that takes `rowObject` as
 *     an argument and returns the value of the cell for that column.
 *   - @valueName {string} if valueFunction is not defined, cell value will use
 *     valueName to pull that attribute from the rowObject.
 *   - @footer {string} footer cell value for the column
 * - @rowObjects {array[object]} array of objects used to build the <tr/> rows
 * - @summary {string} table summary
 * - @enablePagination {boolean} whether or not to enablePagination
 * - @casesPerPage {number} how many cases to show per page,
 *   defaults to 15 if nothing is set
 *
 * see StyleGuideTables.jsx for usage example.
 */

const helperClasses = {
  center: 'cf-txt-c',
  left: 'cf-txt-l',
  right: 'cf-txt-r'
};

const DEFAULT_CASES_PER_PAGE = 15;

const cellClasses = ({ align, cellClass }) => classnames([helperClasses[align], cellClass]);

const getColumns = (props) => {
  return _.isFunction(props.columns) ?
    props.columns(props.rowObject) : props.columns;
};

const HeaderRow = (props) => {
  const iconHeaderStyle = css({ display: 'table-row' });
  const iconStyle = css({
    display: 'table-cell',
    paddingLeft: '1rem',
    paddingTop: '0.3rem',
    verticalAlign: 'middle'
  }, hover({ cursor: 'pointer' }));

  return <thead className={props.headerClassName}>
    <tr>
      {getColumns(props).map((column, columnNumber) => {
        let sortIcon;
        let filterIcon;

        if ((!props.useTaskPagesApi || column.backendCanSort) && column.getSortValue) {
          const topColor = props.sortColName === column.name && !props.sortAscending ?
            COLORS.PRIMARY :
            COLORS.GREY_LIGHT;
          const botColor = props.sortColName === column.name && props.sortAscending ?
            COLORS.PRIMARY :
            COLORS.GREY_LIGHT;

          sortIcon = <span {...iconStyle} onClick={() => props.setSortOrder(column.name)}>
            <DoubleArrow topColor={topColor} bottomColor={botColor} />
          </span>;
        }

        // Keeping the historical prop `getFilterValues` for backwards compatibility,
        // will remove this once all apps are using this new component.
        if (!props.useTaskPagesApi && (column.enableFilter || column.getFilterValues)) {
          filterIcon = <TableFilter
            {...column}
            updateFilters={(newFilters) => props.updateFilteredByList(newFilters)}
            filteredByList={props.filteredByList} />;
        }

        const columnTitleContent = <span>{column.header || ''}</span>;
        const columnContent = <span {...iconHeaderStyle}>
          {columnTitleContent}
          {sortIcon}
          {filterIcon}
        </span>;

        return <th scope="col" key={columnNumber} className={cellClasses(column)}>
          { column.tooltip ?
            <Tooltip id={`tooltip-${columnNumber}`} text={column.tooltip}>{columnContent}</Tooltip> :
            <React.Fragment>{columnContent}</React.Fragment>
          }
        </th>;
      })}
    </tr>
  </thead>;
};

const getCellValue = (rowObject, rowId, column) => {
  if (column.valueFunction) {
    return column.valueFunction(rowObject, rowId);
  }
  if (column.valueName) {
    return rowObject[column.valueName];
  }

  return '';
};

const getCellSpan = (rowObject, column) => {
  if (column.span) {
    return column.span(rowObject);
  }

  return 1;
};

// todo: make these functional components?
class Row extends React.PureComponent {
  render() {
    const props = this.props;
    const rowId = props.footer ? 'footer' : props.rowId;
    const rowClassnameCondition = classnames(!props.footer && props.rowClassNames(props.rowObject));

    return <tr id={`table-row-${rowId}`} className={rowClassnameCondition}>
      {getColumns(props).
        filter((column) => getCellSpan(props.rowObject, column) > 0).
        map((column, columnNumber) =>
          <td
            key={columnNumber}
            className={cellClasses(column)}
            colSpan={getCellSpan(props.rowObject, column)}>
            {props.footer ?
              column.footer :
              getCellValue(props.rowObject, props.rowId, column)}
          </td>
        )}
    </tr>;
  }
}

class BodyRows extends React.PureComponent {
  render() {
    const { rowObjects, bodyClassName, columns, rowClassNames, tbodyRef, id, getKeyForRow, bodyStyling } = this.props;

    return <tbody className={bodyClassName} ref={tbodyRef} id={id} {...bodyStyling}>
      {rowObjects && rowObjects.map((object, rowNumber) => {
        const key = getKeyForRow(rowNumber, object);

        return <Row
          rowObject={object}
          columns={columns}
          rowClassNames={rowClassNames}
          key={key}
          rowId={key} />;
      }
      )}
    </tbody>;
  }
}

class FooterRow extends React.PureComponent {
  render() {
    const props = this.props;
    const hasFooters = _.some(props.columns, 'footer');

    return <tfoot>
      {hasFooters && <Row columns={props.columns} footer />}
    </tfoot>;
  }
}

export default class QueueTable extends React.PureComponent {
  constructor(props) {
    super(props);

    const { defaultSort } = this.props;
    const state = {
      sortAscending: true,
      sortColName: null,
      filteredByList: {},
      tasksFromApi: [],
      loadingComponent: null,
      currentPage: 0
    };

    if (defaultSort) {
      Object.assign(state, defaultSort);
    }

    this.state = state;
  }

  defaultRowClassNames = () => ''

  sortRowObjects = () => {
    const { rowObjects } = this.props;
    const {
      sortColName,
      sortAscending
    } = this.state;

    if (sortColName === null) {
      return rowObjects;
    }

    const columnToSortBy = getColumns(this.props).find((column) => sortColName === column.name);

    return _.orderBy(rowObjects, (row) => columnToSortBy.getSortValue(row), sortAscending ? 'asc' : 'desc');
  }

  updateFilteredByList = (newList) => {
    this.setState({ filteredByList: newList });

    // When filters are added or changed, default back to the first page of data
    // because the number of pages could have changed as data is filtered out.
    this.updateCurrentPage(0);
  };

  filterTableData = (data: Array<Object>) => {
    const { filteredByList } = this.state;
    let filteredData = _.clone(data);

    // Only filter the data if filters have been selected
    if (!_.isEmpty(filteredByList)) {
      for (const columnName in filteredByList) {
        // If there are no filters for this columnName,
        // continue to the next columnName
        if (_.isEmpty(filteredByList[columnName])) {
          continue; // eslint-disable-line no-continue
        }

        // Only return the data point if it contains the value of the filter
        filteredData = filteredData.filter((row) => {
          const cellValue = _.get(row, columnName);

          if (typeof cellValue === 'undefined' || cellValue === null) {
            return filteredByList[columnName].includes('null');
          }

          return filteredByList[columnName].includes(cellValue);
        });
      }
    }

    return filteredData;
  };

  paginateData = (tableData) => {
    const casesPerPage = this.props.casesPerPage || DEFAULT_CASES_PER_PAGE;
    const paginatedData = [];

    for (let i = 0; i < tableData.length; i += casesPerPage) {
      paginatedData.push(tableData.slice(i, i + casesPerPage));
    }

    return paginatedData;
  }

  setColumnSortOrder = (colName) => this.setState(
    { sortColName: colName,
      sortAscending: !this.state.sortAscending },
    this.requestTasks
  );

  updateCurrentPage = (newPage) => {
    this.setState(
      { currentPage: newPage },
      this.requestTasks
    );
  }

  // /organizations/vlj-support-staff/tasks?tab=on_hold
  // &page=2
  // &sort_by=detailsColumn
  // &order=desc
  requestUrl = () => {
    // Request currentPage + 1 since our API indexes starting at 1 and the pagination element indexes starting at 0.
    const params = { [QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]: this.state.currentPage + 1 };

    // Add sorting parameters to query string if any sorting parameters have been explicitly set.
    if (this.state.sortColName) {
      params[QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM] = this.state.sortColName;
      params[QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM] = this.state.sortAscending ?
        QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC :
        QUEUE_CONFIG.COLUMN_SORT_ORDER_DESC;
    }

    const queryString = Object.keys(params).map(
      (key) => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`
    ).
      join('&');

    return `${this.props.taskPagesApiEndpoint}&${queryString}`;
  }

  requestTasks = () => {
    if (!this.props.useTaskPagesApi) {
      return;
    }

    this.setState({ loadingComponent: <LoadingScreen spinnerColor={LOGO_COLORS.QUEUE.ACCENT} /> });

    return ApiUtil.get(this.requestUrl()).then((response) => {
      const {
        tasks: { data: tasks }
      } = JSON.parse(response.text);

      this.setState({
        tasksFromApi: tasksWithAppealsFromRawTasks(tasks),
        loadingComponent: null
      });
    }).
      catch(() => {
        this.setState({ loadingComponent: null });
      });
  };

  render() {
    const {
      columns,
      summary,
      headerClassName = '',
      bodyClassName = '',
      rowClassNames = this.defaultRowClassNames,
      getKeyForRow,
      slowReRendersAreOk,
      tbodyId,
      tbodyRef,
      caption,
      id,
      styling,
      bodyStyling,
      enablePagination,
      useTaskPagesApi
    } = this.props;

    let {
      totalTaskCount,
      numberOfPages,
      rowObjects,
      casesPerPage
    } = this.props;

    if (useTaskPagesApi) {
      if (this.state.tasksFromApi.length) {
        rowObjects = this.state.tasksFromApi;
      }
    } else {
      // Steps to calculate table data to display:
      // 1. Sort data
      rowObjects = this.sortRowObjects();

      // 2. Filter data
      rowObjects = this.filterTableData(rowObjects);
      totalTaskCount = rowObjects.length;

      // 3. Generate paginated data
      const paginatedData = this.paginateData(rowObjects);

      numberOfPages = paginatedData.length;

      // 4. Display only the data for the current page
      // paginatedData[this.state.currentPage] will be a subset of all rows I am guessing.
      rowObjects = rowObjects.length ? paginatedData[this.state.currentPage] : rowObjects;

      casesPerPage = DEFAULT_CASES_PER_PAGE;
    }

    let keyGetter = getKeyForRow;

    if (!getKeyForRow) {
      keyGetter = _.identity;
      if (!slowReRendersAreOk) {
        console.warn('<QueueTable> props: one of `getKeyForRow` or `slowReRendersAreOk` props must be passed. ' +
          'To learn more about keys, see https://facebook.github.io/react/docs/lists-and-keys.html#keys');
      }
    }

    let paginationElements = null;

    if (enablePagination) {
      paginationElements = <Pagination
        pageSize={casesPerPage}
        currentPage={this.state.currentPage + 1}
        currentCases={rowObjects.length}
        totalPages={numberOfPages}
        totalCases={totalTaskCount}
        updatePage={(newPage) => this.updateCurrentPage(newPage)} />;
    }

    // Show a spinner if we are loading tasks from the API.
    const body = this.state.loadingComponent ?
      this.state.loadingComponent : <table
        id={id}
        className={`usa-table-borderless ${this.props.className}`}
        summary={summary}
        {...styling} >

        { caption && <caption className="usa-sr-only">{ caption }</caption> }

        <HeaderRow
          columns={columns}
          headerClassName={headerClassName}
          setSortOrder={this.setColumnSortOrder}
          updateFilteredByList={this.updateFilteredByList}
          filteredByList={this.state.filteredByList}
          useTaskPagesApi={useTaskPagesApi}
          {...this.state} />
        <BodyRows
          id={tbodyId}
          tbodyRef={tbodyRef}
          columns={columns}
          getKeyForRow={keyGetter}
          rowObjects={rowObjects}
          bodyClassName={bodyClassName}
          rowClassNames={rowClassNames}
          bodyStyling={bodyStyling}
          {...this.state} />
        <FooterRow columns={columns} />
      </table>;

    return <div className="cf-table-wrapper" ref={(div) => {
      this.elementForFocus = div;
    }}>
      <FilterSummary
        filteredByList={this.state.filteredByList}
        clearFilteredByList={(newList) => this.updateFilteredByList(newList)} />
      { paginationElements }
      { body }
      { paginationElements }
    </div>;
  }
}

QueueTable.propTypes = {
  tbodyId: PropTypes.string,
  tbodyRef: PropTypes.func,
  columns: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.object),
    PropTypes.func]).isRequired,
  rowObjects: PropTypes.arrayOf(PropTypes.object).isRequired,
  rowClassNames: PropTypes.func,
  keyGetter: PropTypes.func,
  slowReRendersAreOk: PropTypes.bool,
  summary: PropTypes.string,
  headerClassName: PropTypes.string,
  className: PropTypes.string,
  caption: PropTypes.string,
  id: PropTypes.string,
  styling: PropTypes.object,
  defaultSort: PropTypes.shape({
    sortColName: PropTypes.string,
    sortAscending: PropTypes.bool
  }),
  userReadableColumnNames: PropTypes.object,
  useTaskPagesApi: PropTypes.bool,
  taskPagesApiEndpoint: PropTypes.string,
  enablePagination: PropTypes.bool,
  casesPerPage: PropTypes.number
};
