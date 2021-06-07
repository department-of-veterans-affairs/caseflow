/* eslint-disable max-lines */

import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';
import { css, hover } from 'glamor';
import _ from 'lodash';
import Tooltip from '../components/Tooltip';
import { DoubleArrow } from '../components/RenderFunctions';
import TableFilter from '../components/TableFilter';
import FilterSummary from '../components/FilterSummary';
import Pagination from '../components/Pagination/Pagination';
import { COLORS, LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import LoadingScreen from '../components/LoadingScreen';
import { tasksWithAppealsFromRawTasks } from './utils';
import QUEUE_CONFIG from '../../constants/QUEUE_CONFIG';
import COPY from '../../COPY';

/**
 * This component can be used to easily build tables.
 * The required props are:
 * - @columns {array[string]} array of objects that define the properties
 *   of the columns. Possible attributes for each column include:
 *   - @align {string} alignment of the column ("left", "right", or "center")
 *   - @anyFiltersAreSet {boolean} determines whether the "Clear All Filters" option
 *     in the dropdown is enabled
 *   - @cellClass {string} a CSS class to apply to each cell in the column
 *   - @columnName {string} the name of the column in the table data
 *   - @enableFilter {boolean} whether filtering is turned on for the column
 *   - @enableFilterTextTransform {boolean} when true, filter text that gets displayed
 *     is automatically capitalized. default is true.
 *   - @filterOptions {array[object]} array of value - displayText pairs to override the
 *     generated filter values and counts in <TableFilter>
 *   - @filterValueTransform {function(any)} function that takes the value of the
 *     column, and transforms it into a string for filtering.
 *   - @footer {string} footer cell value for the column
 *   - @header {string|component} header cell value for the column
 *   - @label {string} used for the aria-label on the icon,
 *   - @tableData {array[object]} array of rows that are being used to populate the table.
 *     if not specified, @rowObjects will used.
 *   - @valueFunction {function(rowObject)} function that takes `rowObject` as
 *     an argument and returns the value of the cell for that column.
 *   - @valueName {string} if valueFunction is not defined, cell value will use
 *     valueName to pull that attribute from the rowObject.
 *   - @filterValueTransform {function(any, any)} function that takes the value of the
 *     column, and transforms it into a string for filtering. The row is passed in as
 *     a second argument.
 *   - @filterOptions {array[object]} array of value - displayText pairs to override the
 *     generated filter values and counts in <TableFilter>
 *   - @enableFilterTextTransform {boolean} when true, filter text that gets displayed
 *     is automatically capitalized. default is true.
 *   - @footer {string} footer cell value for the column

 * - @rowObjects {array[object]} array of objects used to build the <tr/> rows
 * - @summary {string} table summary
 * - @enablePagination {boolean} whether or not to enablePagination
 * - @casesPerPage {number} how many cases to show per page,
 *   defaults to 15 if nothing is set
 *
 * see StyleGuideTables.jsx for usage example.
 */

export const helperClasses = {
  center: 'cf-txt-c',
  left: 'cf-txt-l',
  right: 'cf-txt-r'
};

export const DEFAULT_CASES_PER_PAGE = 15;

export const cellClasses = ({ align, cellClass }) => classnames([helperClasses[align], cellClass]);

export const getColumns = (props) => {
  return _.isFunction(props.columns) ? props.columns(props.rowObject) : props.columns;
};

export const getCellValue = (rowObject, rowId, column) => {
  if (column.valueFunction) {
    return column.valueFunction(rowObject, rowId);
  }
  if (column.valueName) {
    return rowObject[column.valueName];
  }

  return '';
};

export const getCellSpan = (rowObject, column) => {
  if (column.span) {
    return column.span(rowObject);
  }

  return 1;
};

export const HeaderRow = (props) => {
  const iconHeaderStyle = css({ display: 'table-row' });
  const iconStyle = css(
    {
      display: 'table-cell',
      paddingLeft: '1rem',
      paddingTop: '0.3rem',
      verticalAlign: 'middle'
    },
    hover({ cursor: 'pointer' })
  );

  return (
    <thead className={props.headerClassName}>
      <tr role="row">
        {getColumns(props).map((column, columnNumber) => {
          let sortIcon;
          let filterIcon;

          // Determine whether to apply an ID to the column title
          const titleId = column?.columnName ? `header-${_.camelCase(column.columnName)}` : '';

          // Define the aria label to exclude the filter/sort
          const ariaLabel = column?.ariaLabel ? column?.ariaLabel : titleId;

          // Set the Sort name for the column if sorting by this column
          const sorting = props.sortColName === column.name;
          const sortLabel = sorting && props.sortAscending ? 'ascending' : 'descending';

          // Set the aria props for this column header
          const sortProps = sorting ? { 'aria-sort': sortLabel } : {};

          if ((!props.useTaskPagesApi || column.backendCanSort) && column.getSortValue) {
            const topColor = sorting && !props.sortAscending ? COLORS.PRIMARY : COLORS.GREY_LIGHT;
            const botColor = sorting && props.sortAscending ? COLORS.PRIMARY : COLORS.GREY_LIGHT;
console.log(column);
            sortIcon = (
              <span
                {...iconStyle}
                aria-label={`Sort by ${column.header}`}
                role="button"
                tabIndex="0"
                onClick={() => props.setSortOrder(column.name)}
              >
                <DoubleArrow topColor={topColor} bottomColor={botColor} />
              </span>
            );
          }

          // Keeping the historical prop `getFilterValues` for backwards compatibility,
          // will remove this once all apps are using this new component.
          if (!props.useTaskPagesApi && (column.enableFilter || column.getFilterValues)) {
            filterIcon = (
              <TableFilter
                {...column}
                tableData={column.tableData || props.rowObjects}
                valueTransform={column.filterValueTransform}
                updateFilters={(newFilters) => props.updateFilteredByList(newFilters)}
                filteredByList={props.filteredByList}
              />
            );
          } else if (props.useTaskPagesApi && column.filterOptions) {
            filterIcon = (
              <TableFilter
                {...column}
                tableData={column.tableData || props.rowObjects}
                filterOptionsFromApi={props.useTaskPagesApi && column.filterOptions}
                updateFilters={(newFilters) => props.updateFilteredByList(newFilters)}
                filteredByList={props.filteredByList}
              />
            );
          }
          const columnTitleContent = <span {...(titleId ? { id: titleId } : {})}>{column.header || ''}</span>;
          const columnContent = (
            <span {...iconHeaderStyle} aria-label="">
              {columnTitleContent}
              {sortIcon}
              {filterIcon}
            </span>
          );

          return (
            <th
              {...sortProps}
              {...(column?.sortProps || {})}
              {...(ariaLabel ? { 'aria-labelledby': ariaLabel } : {})}
              role="columnheader"
              scope="col"
              key={columnNumber}
              className={cellClasses(column)}
            >
              {column.tooltip ? (
                <Tooltip id={`tooltip-${columnNumber}`} text={column.tooltip}>
                  {columnContent}
                </Tooltip>
              ) : (
                <React.Fragment>{columnContent}</React.Fragment>
              )}
            </th>
          );
        })}
      </tr>
    </thead>
  );
};

// todo: make these functional components?
export class Row extends React.PureComponent {
  render() {
    const props = this.props;
    const rowId = props.footer ? 'footer' : props.rowId;
    const rowClassnameCondition = classnames(!props.footer && props.rowClassNames(props.rowObject));

    return (
      <tr id={`table-row-${rowId}`} className={rowClassnameCondition} role="row">
        {getColumns(props).
          filter((column) => getCellSpan(props.rowObject, column) > 0).
          map((column, columnNumber) => (
            <td
              role="cell"
              key={columnNumber}
              className={cellClasses(column)}
              colSpan={getCellSpan(props.rowObject, column)}
            >
              {props.footer ? column.footer : getCellValue(props.rowObject, props.rowId, column)}
            </td>
          ))}
      </tr>
    );
  }
}

export class BodyRows extends React.PureComponent {
  render() {
    const { rowObjects, bodyClassName, columns, rowClassNames, tbodyRef, id, getKeyForRow, bodyStyling } = this.props;

    return (
      <tbody className={bodyClassName} ref={tbodyRef} id={id} {...bodyStyling}>
        {rowObjects &&
          rowObjects.map((object, rowNumber) => {
            const key = getKeyForRow(rowNumber, object);

            return <Row rowObject={object} columns={columns} rowClassNames={rowClassNames} key={key} rowId={key} />;
          })}
      </tbody>
    );
  }
}

export class FooterRow extends React.PureComponent {
  render() {
    const props = this.props;
    const hasFooters = _.some(props.columns, 'footer');

    return <tfoot>{hasFooters && <Row columns={props.columns} footer />}</tfoot>;
  }
}

export default class QueueTable extends React.PureComponent {
  constructor(props) {
    super(props);

    const { useTaskPagesApi } = this.props;
    const validatedPaginationOptions = this.validatedPaginationOptions();

    this.state = this.initialState(validatedPaginationOptions);

    if (useTaskPagesApi && validatedPaginationOptions.needsTaskRequest) {
      this.requestTasks();
    }

    this.updateAddressBar();
  }

  initialState = (paginationOptions) => {
    const { defaultSort, useTaskPagesApi } = this.props;

    const state = {
      cachedResponses: {},
      tasksFromApi: null,
      loadingComponent: useTaskPagesApi && paginationOptions.needsTaskRequest && (
        <LoadingScreen spinnerColor={LOGO_COLORS.QUEUE.ACCENT} />
      ),
      ...paginationOptions
    };

    if (defaultSort) {
      Object.assign(state, defaultSort);
    }

    return state;
  };

  validatedPaginationOptions = () => {
    const { tabPaginationOptions = {}, numberOfPages, columns } = this.props;

    const sortAscending =
      tabPaginationOptions[QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM] !== QUEUE_CONFIG.COLUMN_SORT_ORDER_DESC;
    const sortColumn = tabPaginationOptions[QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM] || null;
    const filteredByList = this.getFilters(tabPaginationOptions[`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`]);
    const pageNumber = tabPaginationOptions[QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM] - 1 || 0;

    const currentPage = pageNumber + 1 > numberOfPages || pageNumber < 0 ? 0 : pageNumber;
    const sortColName = columns.map((column) => column.name).includes(sortColumn) ? sortColumn : null;

    // Only request tasks from the back end if no pages have been fetches, we want another page,
    // to sort on a column, or if filters are provided
    const needsTaskRequest = _.isUndefined(numberOfPages) || currentPage || sortColName || !_.isEmpty(filteredByList);

    return {
      sortAscending,
      sortColName,
      filteredByList,
      currentPage,
      needsTaskRequest
    };
  };

  componentDidMount = () => {
    const firstResponse = {
      task_page_count: this.props.numberOfPages,
      tasks_per_page: this.props.casesPerPage,
      total_task_count: this.props.rowObjects.length,
      tasks: this.props.rowObjects
    };

    if (this.props.rowObjects.length) {
      this.setState({ cachedResponses: { ...this.state.cachedResponses, [this.requestUrl()]: firstResponse } });
    }
  };

  getFilters = (filterParams) => {
    const filters = {};

    // filter: ["col=typeColumn&val=Original", "col=taskColumn&val=OtherColocatedTask|ArnesonColocatedTask"]
    if (filterParams) {
      // When react router encouters an array of strings param with one element, it converts the param to a string
      // rather than keeping it as the original array
      (Array.isArray(filterParams) ? filterParams : [filterParams]).forEach((filter) => {
        const columnAndValues = filter.split('&');
        const columnName = columnAndValues[0].split('=')[1];
        const column = this.props.columns.find((col) => col.name === columnName);
        const values = columnAndValues[1].split('=')[1].split('|');

        if (column) {
          const validValues = column.filterOptions.map((filterOption) => filterOption.value);

          filters[column.columnName] = values.filter((value) => validValues.includes(value));
        }
      });
    }

    return filters;
  };

  defaultRowClassNames = () => '';

  sortRowObjects = () => {
    const { rowObjects } = this.props;
    const { sortColName, sortAscending } = this.state;

    if (sortColName === null) {
      return rowObjects;
    }

    const columnToSortBy = getColumns(this.props).find((column) => sortColName === column.name);

    return _.orderBy(rowObjects, (row) => columnToSortBy.getSortValue(row), sortAscending ? 'asc' : 'desc');
  };

  updateFilteredByList = (newList) => {
    this.setState({ filteredByList: newList, filtered: true }, this.updateAddressBar);

    // When filters are added or changed, default back to the first page of data
    // because the number of pages could have changed as data is filtered out.
    this.updateCurrentPage(0);
  };

  filterTableData = (data) => {
    const { columns } = this.props;
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

        // Find the column configuration so any transform functions can
        // be applied to the row when filtering.
        const matchColumnConfigIndex = _.findIndex(columns, (column) => column.columnName === columnName);
        let columnConfig;

        if (matchColumnConfigIndex > 0) {
          columnConfig = columns[matchColumnConfigIndex];
        }

        // Only return the data point if it contains the value of the filter
        filteredData = filteredData.filter((row) => {
          let cellValue = _.get(row, columnName);

          if (columnConfig && columnConfig.filterValueTransform) {
            cellValue = columnConfig.filterValueTransform(cellValue, row);
          }

          if (_.isNil(cellValue)) {
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

    if (this.props.enablePagination) {
      for (let i = 0; i < tableData.length; i += casesPerPage) {
        paginatedData.push(tableData.slice(i, i + casesPerPage));
      }
    } else {
      paginatedData.push(tableData);
    }

    return paginatedData;
  };

  setColumnSortOrder = (colName) =>
    this.setState({ sortColName: colName, sortAscending: !this.state.sortAscending }, this.requestTasks);

  updateCurrentPage = (newPage) => {
    this.setState({ currentPage: newPage }, this.requestTasks);
  };

  updateAddressBar = () => {
    if (this.props.useTaskPagesApi) {
      history.pushState('', '', this.deepLink());
    }
  };

  deepLink = () => {
    const base = `${window.location.origin}${window.location.pathname}`;
    const tab = this.props.taskPagesApiEndpoint.split('?')[1];

    return `${base}?${tab}${this.requestQueryString()}`;
  };

  // /organizations/vlj-support-staff/tasks?tab=on_hold
  // &page=2
  // &sort_by=detailsColumn
  // &order=desc
  // &filter[]=col=docketNumberColumn&val=legacy|evidence_submission&filters[]=col=taskColumn&val=Unaccredited rep
  requestUrl = () => {
    return `${this.props.taskPagesApiEndpoint}${this.requestQueryString()}`;
  };

  requestQueryString = () => {
    const { filteredByList } = this.state;
    const filterParams = [];

    // Request currentPage + 1 since our API indexes starting at 1 and the pagination element indexes starting at 0.
    const params = { [QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]: this.state.currentPage + 1 };

    // Add sorting parameters to query string if any sorting parameters have been explicitly set.
    if (this.state.sortColName) {
      params[QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM] = this.state.sortColName;
      params[QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM] = this.state.sortAscending ?
        QUEUE_CONFIG.COLUMN_SORT_ORDER_ASC :
        QUEUE_CONFIG.COLUMN_SORT_ORDER_DESC;
    }

    if (!_.isEmpty(filteredByList)) {
      for (const columnName in filteredByList) {
        if (!_.isEmpty(filteredByList[columnName])) {
          const column = this.props.columns.find((col) => col.columnName === columnName);

          filterParams.push(`col=${column.name}&val=${filteredByList[columnName].join('|')}`);
        }
      }
    }

    const queryString = Object.keys(params).
      map((key) => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`).
      concat(
        filterParams.map(
          (filterParam) =>
            `${encodeURIComponent(`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`)}=${encodeURIComponent(filterParam)}`
        )
      ).
      join('&');

    return `&${queryString}`;
  };

  requestTasks = () => {
    if (!this.props.useTaskPagesApi) {
      return;
    }

    const endpointUrl = this.requestUrl();

    // If we already have the tasks cached then we set the state and return early.
    const responseFromCache = this.state.cachedResponses[endpointUrl];

    if (responseFromCache) {
      this.setState({ tasksFromApi: responseFromCache.tasks });

      return Promise.resolve(true);
    }

    this.setState({ loadingComponent: <LoadingScreen spinnerColor={LOGO_COLORS.QUEUE.ACCENT} /> });

    return ApiUtil.get(endpointUrl).
      then((response) => {
        const {
          tasks: { data: tasks }
        } = response.body;

        const preparedTasks = tasksWithAppealsFromRawTasks(tasks);

        const preparedResponse = Object.assign(response.body, { tasks: preparedTasks });

        this.setState({
          cachedResponses: { ...this.state.cachedResponses, [endpointUrl]: preparedResponse },
          tasksFromApi: preparedTasks,
          loadingComponent: null
        });

        this.updateAddressBar();
      }).
      catch(() => this.setState({ loadingComponent: null }));
  };

  render() {
    const {
      columns,
      summary,
      headerClassName,
      bodyClassName,
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

    let { totalTaskCount, numberOfPages, rowObjects, casesPerPage } = this.props;

    if (useTaskPagesApi) {
      // Use null instead of array length of zero because the intersection of several filters may result in an empty
      // array of rows being returned from the API.
      if (this.state.tasksFromApi !== null) {
        rowObjects = this.state.tasksFromApi;

        // If we already have the response cached then use the attributes of the response to set the pagination vars.
        const endpointUrl = this.requestUrl();
        const responseFromCache = this.state.cachedResponses[endpointUrl];

        if (responseFromCache) {
          numberOfPages = responseFromCache.task_page_count;
          totalTaskCount = responseFromCache.total_task_count;
        }

        if (this.props.tabPaginationOptions && this.props.tabPaginationOptions.onPageLoaded) {
          this.props.tabPaginationOptions.onPageLoaded(responseFromCache, this.state.currentPage, this.state.filtered);
        }
      }
    } else {
      // Steps to calculate table data to display:
      // 1. Sort data
      rowObjects = this.sortRowObjects();

      // 2. Filter data
      rowObjects = this.filterTableData(rowObjects);
      totalTaskCount = rowObjects ? rowObjects.length : 0;

      // 3. Generate paginated data
      const paginatedData = this.paginateData(rowObjects);

      numberOfPages = paginatedData.length;

      // 4. Display only the data for the current page
      // paginatedData[this.state.currentPage] will be a subset of all rows I am guessing.
      rowObjects = rowObjects && rowObjects.length ? paginatedData[this.state.currentPage] : rowObjects;

      casesPerPage = DEFAULT_CASES_PER_PAGE;
    }

    let keyGetter = getKeyForRow;

    if (!getKeyForRow) {
      keyGetter = _.identity;
      if (!slowReRendersAreOk) {
        console.warn(
          '<QueueTable> props: one of `getKeyForRow` or `slowReRendersAreOk` props must be passed. ' +
            'To learn more about keys, see https://facebook.github.io/react/docs/lists-and-keys.html#keys'
        );
      }
    }

    let paginationElements = null;

    if (enablePagination && !this.state.loadingComponent) {
      paginationElements = (
        <Pagination
          pageSize={casesPerPage || DEFAULT_CASES_PER_PAGE}
          currentPage={this.state.currentPage + 1}
          currentCases={rowObjects ? rowObjects.length : 0}
          totalPages={numberOfPages}
          totalCases={totalTaskCount}
          updatePage={(newPage) => this.updateCurrentPage(newPage)}
        />
      );
    }

    // Show a spinner if we are loading tasks from the API.
    const body = this.state.loadingComponent ? (
      this.state.loadingComponent
    ) : (
      <table
        aria-label={COPY.CASE_LIST_TABLE_TITLE}
        aria-describedby="case-table-description"
        role="table"
        id={id}
        className={`usa-table-borderless ${this.props.className}`}
        {...styling}
      >
        {summary && (
          <caption id="case-table-description" className="usa-sr-only">
            {summary}
          </caption>
        )}

        <HeaderRow
          columns={columns}
          rowObjects={rowObjects}
          headerClassName={headerClassName}
          setSortOrder={this.setColumnSortOrder}
          updateFilteredByList={this.updateFilteredByList}
          filteredByList={this.state.filteredByList}
          useTaskPagesApi={useTaskPagesApi}
          {...this.state}
        />
        <BodyRows
          id={tbodyId}
          tbodyRef={tbodyRef}
          columns={columns}
          getKeyForRow={keyGetter}
          rowObjects={rowObjects}
          bodyClassName={bodyClassName ?? ''}
          rowClassNames={rowClassNames}
          bodyStyling={bodyStyling}
          {...this.state}
        />
        <FooterRow rowObjects={[]} columns={columns} />
      </table>
    );

    return (
      <div
        className="cf-table-wrapper"
        ref={(div) => {
          this.elementForFocus = div;
        }}
      >
        <FilterSummary
          filteredByList={this.state.filteredByList}
          clearFilteredByList={(newList) => this.updateFilteredByList(newList)}
        />
        {paginationElements}
        {body}
        {paginationElements}
      </div>
    );
  }
}

HeaderRow.propTypes = FooterRow.propTypes = Row.propTypes = BodyRows.propTypes = QueueTable.propTypes = {
  tbodyId: PropTypes.string,
  tbodyRef: PropTypes.func,
  columns: PropTypes.oneOfType([PropTypes.arrayOf(PropTypes.object), PropTypes.func]).isRequired,
  rowObjects: PropTypes.arrayOf(PropTypes.object).isRequired,
  rowClassNames: PropTypes.func,
  keyGetter: PropTypes.func,
  slowReRendersAreOk: PropTypes.bool,
  summary: PropTypes.string,
  headerClassName: PropTypes.string,
  className: PropTypes.string,
  bodyClassName: PropTypes.string,
  bodyStyling: PropTypes.object,
  caption: PropTypes.string,
  casesPerPage: PropTypes.number,
  defaultSort: PropTypes.shape({
    sortColName: PropTypes.string,
    sortAscending: PropTypes.bool
  }),
  enablePagination: PropTypes.bool,
  getKeyForRow: PropTypes.func,
  id: PropTypes.string,
  numberOfPages: PropTypes.number,
  sortAscending: PropTypes.bool,
  sortColName: PropTypes.string,
  styling: PropTypes.object,
  taskPagesApiEndpoint: PropTypes.string,
  totalTaskCount: PropTypes.number,
  useTaskPagesApi: PropTypes.bool,
  userReadableColumnNames: PropTypes.object,
  tabPaginationOptions: PropTypes.shape({
    [QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]: PropTypes.string,
    [QUEUE_CONFIG.SORT_DIRECTION_REQUEST_PARAM]: PropTypes.string,
    [QUEUE_CONFIG.SORT_COLUMN_REQUEST_PARAM]: PropTypes.string,
    [`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`]: PropTypes.arrayOf(PropTypes.string),
    onPageLoaded: PropTypes.func
  })
};

/* eslint-enable max-lines */
