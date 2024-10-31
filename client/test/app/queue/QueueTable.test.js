/* eslint-disable max-lines */
import React from 'react';
import * as queueTable from 'app/queue/QueueTable';
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react';
import {
  initState,
  columns,
  createTask,
  summary,
  headerStyle,
  rowObject,
  rowId,
  sortColumns,
  columnsWithTooltip,
  backendSortColumns,
  filterColumns,
  filterColumnsWithOptions,
  filterColumnsWithValues,
  tableData,
  footerColumns,
  baseColumns
} from 'test/data';
import { COLORS, LOGO_COLORS } from 'app/constants/AppConstants';
import * as glamor from 'glamor';
import classnames from 'classnames';
import { times } from 'lodash';
import {
  selectFromDropdown,
  clickSubmissionButton,
  enterInputValue
} from '../queue/components/modalUtils';
import { datePickerFilterValue } from 'app/components/DatePicker';
import { encodeQueryParams } from 'app/util/QueryParamsUtil';
import { when } from 'jest-when';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('classnames');

jest.mock('app/util/ApiUtil', () => ({
  get: jest.fn().mockResolvedValue({})
}));

const { default: QueueTable, HeaderRow, BodyRows, FooterRow, Row } = queueTable;

describe('QueueTable', () => {
  describe('Local Methods', () => {
    beforeEach(() => {
      jest.spyOn(queueTable, 'getColumns');
      jest.spyOn(queueTable, 'cellClasses');

      classnames.mockReturnValue('testClasses');
    });

    test('function cellClasses({ align, cellClass}) returns classes based on alignment', () => {
      // Left alignment
      const className = queueTable.cellClasses({ align: 'left' });

      expect(classnames).toHaveBeenCalledWith([queueTable.helperClasses.left, undefined]);

      // Right alignment
      queueTable.cellClasses({ align: 'right' });
      expect(classnames).toHaveBeenCalledWith([queueTable.helperClasses.right, undefined]);

      // Center alignment
      queueTable.cellClasses({ align: 'center' });
      expect(classnames).toHaveBeenCalledWith([queueTable.helperClasses.center, undefined]);

      // No alignment specified
      queueTable.cellClasses({ align: '' });
      expect(classnames).toHaveBeenCalledWith([undefined, undefined]);

      // With cellClass provieded
      queueTable.cellClasses({ align: '', cellClass: 'test' });
      expect(classnames).toHaveBeenCalledWith([undefined, 'test']);

      // Check the returned className
      expect(className).toEqual('testClasses');
    });

    test('function getColumns(props) returns value when column is not a function', () => {
      // Run the test
      const result = queueTable.getColumns({ columns: 'test' });

      // Assertions
      expect(result).toEqual('test');
    });

    test('function getColumns(props) calls column function when it is not a value', () => {
      // Run the test
      const row = {};
      const spy = jest.fn().mockReturnValue('spied');
      const result = queueTable.getColumns({ columns: spy, rowObject: row });

      // Assertions
      expect(result).toEqual('spied');
      expect(spy).toHaveBeenCalledWith(row);
    });

    test('function getCellValue(rowObject, rowId, column) calls the valueFunction when set on column', () => {
      // Run the test
      const result = queueTable.getCellValue(rowObject, rowId, columns[0]);

      // Assertions
      expect(result).toEqual('fizz');
      expect(columns[0].valueFunction).toHaveBeenCalledWith(rowObject, rowId);
    });

    test('function getCellValue(rowObject, rowId, column) returns value name when set on column', () => {
      // Run the test
      const result = queueTable.getCellValue(rowObject, rowId, columns[2]);

      // Assertions
      expect(result).toEqual('Something');
    });

    test('function getCellValue(rowObject, rowId, column) returns empty when neither function nor name are set on column', () => {
      // Run the test
      const result = queueTable.getCellValue(rowObject, rowId, {});

      // Assertions
      expect(result).toEqual('');
    });

    test('function getCellSpan(rowObject, column) returns 1 if valueFunciton is not present on column', () => {
      // Run the test
      const result = queueTable.getCellSpan(rowObject, columns[2]);

      // Assertions
      expect(result).toEqual(1);
      expect(columns[0].span).not.toHaveBeenCalledWith(rowObject);
    });

    test('function getCellSpan(rowObject, column) returns valueFunction results when present on column', () => {
      // Run the test
      const result = queueTable.getCellSpan(rowObject, columns[0]);

      // Assertions
      expect(result).toEqual(2);
      expect(columns[0].span).toHaveBeenCalledWith(rowObject);
    });
  });

  describe('HeaderRow', () => {
    beforeEach(() => {
      // Mock the CSS Module
      jest.spyOn(glamor, 'css');
      jest.spyOn(glamor, 'hover');
    });

    test('Matches snapshot with default props', () => {
      // Setup the test
      glamor.css.mockReturnValueOnce(headerStyle);
      glamor.hover.mockReturnValue('test-class');

      // Run the test
      const {asFragment} = render(
        <HeaderRow
          columns={columns}
          rowObjects={createTask(3)}
          />
        );

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(screen.getByRole('row')).toBeInTheDocument();
      expect(screen.getByRole('row')).toHaveAttribute('role', 'row');
      expect(screen.getAllByRole('columnheader')).toHaveLength(3);

      // // Test each header individually
      columns.forEach((column, i) => {
        const columnHeader = screen.getAllByRole('columnheader')[i];
        expect(columnHeader).toHaveAttribute('role', 'columnheader');
        expect(columnHeader).toHaveTextContent(column.header);
      });

      // // Test the CSS classes
      expect(glamor.css).toHaveBeenNthCalledWith(1, { display: 'table-row' });
      expect(glamor.css).toHaveBeenNthCalledWith(
        2,
        {
          display: 'table-cell',
          paddingLeft: '1rem',
          paddingTop: '0.3rem',
          verticalAlign: 'middle'
        },
        'test-class'
      );
      expect(glamor.hover).toHaveBeenCalledWith({ cursor: 'pointer' });
    });

    test('Can sort when not using the tasks API and getting column sort value', () => {
      // Setup the test
      const sortMock = jest.fn();

      // Run the test
      const {asFragment, container, rerender} = render(
        <HeaderRow
          setSortOrder={sortMock}
          columns={sortColumns}
          rowObjects={tableData}
          />
        );

      // Find the sort button
      const sortButton = screen.getByRole('button', { name: 'Sort by Third' });
      fireEvent.click(sortButton);

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(container.querySelector('.table-icon')).toBeInTheDocument();
      expect(sortMock).toHaveBeenCalledWith(sortColumns[2].name);

      // Test sorting colors
      expect(screen.getByTestId('topColorGroup')).toHaveAttribute('fill', COLORS.GREY_LIGHT);
      expect(screen.getByTestId('bottomColorGroup')).toHaveAttribute('fill', COLORS.GREY_LIGHT);

      // Test Ascending the sort order
      rerender(
        <HeaderRow
          setSortOrder={sortMock}
          columns={sortColumns}
          rowObjects={tableData}
          sortColName='type'
          sortAscending={true}
          />
      )
      expect(screen.getByTestId('topColorGroup')).toHaveAttribute('fill', COLORS.GREY_LIGHT);
      expect(screen.getByTestId('bottomColorGroup')).toHaveAttribute('fill', COLORS.PRIMARY);

      // Test Descending the sort order
      rerender(
        <HeaderRow
          setSortOrder={sortMock}
          columns={sortColumns}
          rowObjects={tableData}
          sortColName='type'
          sortAscending={false}
          />
      )
      expect(screen.getByTestId('topColorGroup')).toHaveAttribute('fill', COLORS.PRIMARY);
      expect(screen.getByTestId('bottomColorGroup')).toHaveAttribute('fill', COLORS.GREY_LIGHT);
    });

    test('Can sort when the backend can sort and getting column sort value', () => {
      // Setup the test
      const sortMock = jest.fn();

      // Run the test
      const {asFragment, container, rerender} = render(
        <HeaderRow
          useTaskPagesApi
          setSortOrder={sortMock}
          columns={backendSortColumns}
          rowObjects={tableData}
        />
      );

      // Find the sort button
      const sortButton = screen.getByRole('button', { name: 'Sort by Third' });
      fireEvent.click(sortButton);

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(container.querySelector('.table-icon')).toBeInTheDocument();
      expect(sortMock).toHaveBeenCalledWith(backendSortColumns[2].name);

      // Test sorting colors
      expect(screen.getByTestId('topColorGroup')).toHaveAttribute('fill', COLORS.GREY_LIGHT);
      expect(screen.getByTestId('bottomColorGroup')).toHaveAttribute('fill', COLORS.GREY_LIGHT);

      // Test Ascending the sort order
      rerender(
        <HeaderRow
          setSortOrder={sortMock}
          columns={sortColumns}
          rowObjects={tableData}
          sortColName='type'
          sortAscending={true}
          />
      )
      expect(screen.getByTestId('topColorGroup')).toHaveAttribute('fill', COLORS.GREY_LIGHT);
      expect(screen.getByTestId('bottomColorGroup')).toHaveAttribute('fill', COLORS.PRIMARY);

      // Test Descending the sort order
      rerender(
        <HeaderRow
          setSortOrder={sortMock}
          columns={sortColumns}
          rowObjects={tableData}
          sortColName='type'
          sortAscending={false}
          />
      )
      expect(screen.getByTestId('topColorGroup')).toHaveAttribute('fill', COLORS.PRIMARY);
      expect(screen.getByTestId('bottomColorGroup')).toHaveAttribute('fill', COLORS.GREY_LIGHT);
    });

    test('Can filter when not using task pages API and filtering is enabled', () => {
      const filteredByList = {}
      // Run the test
      const {asFragment} = render(
        <HeaderRow
          columns={filterColumns}
          rowObjects={tableData}
          filteredByList={filteredByList}
        />
      );

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(screen.getByTestId('table-filter-testid')).toBeInTheDocument();
    });

    test('Can filter when not using task pages API and getting filter values', () => {
      const filteredByList = {}
      // Run the test
      const {asFragment} = render(
        <HeaderRow
        columns={filterColumnsWithValues}
        rowObjects={tableData}
        filteredByList={filteredByList}
        />
      );

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(screen.getByTestId('table-filter-testid')).toBeInTheDocument();
    });

    test('Can filter when using task pages API and column has filter options', () => {
      const filteredByList = {}
      // Run the test
      const {asFragment} = render(
        <HeaderRow
          useTaskPagesApi
          columns={filterColumnsWithOptions}
          rowObjects={tableData}
          filteredByList={filteredByList}
          />
        );


      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(screen.getByTestId('table-filter-testid')).toBeInTheDocument();
    });

    test('Renders tooltip when present on the column', () => {
      // Run the test
      const {asFragment} = render(
        <HeaderRow
        useTaskPagesApi
        columns={columnsWithTooltip}
        rowObjects={tableData}
        />
      );

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(screen.getByTestId('tooltip-testid')).toBeInTheDocument();
      expect(screen.getByText(columnsWithTooltip[2].header)).toBeInTheDocument();
    });
  });

  describe('Row', () => {
    test('Matches snapshot with default props', () => {
      // Setup the test
      const rowClassNames = jest.fn().mockReturnValue('test');

      // Run the test
      const {asFragment}= render(
        <Row
        rowClassNames={rowClassNames}
        columns={baseColumns}
        rowObjects={tableData}
        rowObject={tableData[0]}
        />
      );

      // Assertions
      expect(asFragment()).toMatchSnapshot();

      expect(screen.getByRole('row')).toBeInTheDocument();
      expect(screen.getByRole('row')).toHaveAttribute('role', 'row');
      expect(screen.getAllByRole('gridcell')).toHaveLength(2);

      // Test each cell individually
      const cells = screen.getAllByRole('gridcell');
      cells.forEach((cell, i) => {
        expect(cell).toHaveAttribute('role', 'gridcell');
        expect(cell).toHaveTextContent(tableData[0][baseColumns[i].valueName]);
      });
    });

    test('Renders footer when the column is set to a footer', () => {
      // Setup the test
      const rowClassNames = jest.fn().mockReturnValue('test');

      // Run the test
      const {asFragment}= render(
        <Row
          footer
          rowClassNames={rowClassNames}
          columns={footerColumns}
          rowObjects={tableData}
          rowObject={tableData[2]}
        />
      );

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(screen.getByText(footerColumns[2].footer)).toBeInTheDocument();
    });
  });

  describe('BodyRows', () => {
    jest.spyOn(console, 'error').mockReturnValue();

    test('Matches snapshot with default props', () => {
      // Setup the test
      const getKeyForRow = jest.fn();
      const mockRowClassNames = jest.fn().mockReturnValue('some-class-name');

      // Run the test
      const {asFragment, container} = render(
        <BodyRows
          getKeyForRow={getKeyForRow}
          columns={filterColumns}
          rowObjects={tableData}
          rowClassNames={mockRowClassNames}
          />
        );

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(container.querySelector('tbody')).toBeInTheDocument();
      expect(screen.getAllByRole('row')).toHaveLength(3);
      times(tableData.length).map((index) => {
        expect(getKeyForRow).toHaveBeenNthCalledWith(index + 1, index, tableData[index]);
      });
    });
  });

  describe('FooterRow', () => {
    jest.spyOn(console, 'error').mockReturnValue();

    test('Matches snapshot with default props', () => {
      // Run the test
      const {container, asFragment} = render(
        <FooterRow
        columns={footerColumns}
        />
      );

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(container.querySelector('tfoot')).toBeInTheDocument();
      expect(container.querySelector('#table-row-footer')).toBeInTheDocument();
    });

    test('Renders no footer when not present in the column', () => {
      // Run the test
      const {container, asFragment} = render(
        <FooterRow
        columns={baseColumns}
        />
      );

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(container.querySelector('tfoot')).toBeInTheDocument();
      expect(container.querySelector('#table-row-footer')).not.toBeInTheDocument();
    });
  });

  describe('Class Methods', () => {
    const getFiberNode = (element) => {
      const key = Object.keys(element).find(key => key.startsWith('__reactFiber$'));
      return element[key];
    };

    function extractPropsAndState(fiberNode) {
      if (!fiberNode) return null;

      // Traverse up the tree to find the relevant component node
      while (fiberNode.return) {
        fiberNode = fiberNode.return;
        if (fiberNode.memoizedProps && fiberNode.memoizedState) {
          return {
            pendingProps: fiberNode.pendingProps,
            memoizedProps: fiberNode.memoizedProps,
            memoizedState: fiberNode.memoizedState,
          };
        }
      }
      return null;
    }

    test('function initialState(paginationOptions) returns state', () => {
      // Setup the test
      render(
        <QueueTable
          columns={columns}
          rowObjects={createTask(3)}
          summary={summary}
          slowReRendersAreOk
        />
      );

      const queueTable = screen.getByTestId('queue-table-data-testid');
      const fiberNode = getFiberNode(queueTable);
      const extractedData = extractPropsAndState(fiberNode);
      const memoizedState = extractedData.memoizedState;
      // Assertions
      Object.entries(initState).forEach(([key, value]) => {
        expect(memoizedState).toHaveProperty(key, value);
      });
    });

    test('function initialState(paginationOptions) returns state with default sort when set', () => {
      // Setup the test
      render(
        <QueueTable
          columns={columns}
          rowObjects={createTask(3)}
          summary={summary}
          slowReRendersAreOk
          defaultSort={{ test: '' }}
        />
      );

      const queueTable = screen.getByTestId('queue-table-data-testid');
      const fiberNode = getFiberNode(queueTable);
      const extractedData = extractPropsAndState(fiberNode);
      const memoizedState = extractedData.memoizedState;

      // Assertions
      Object.entries(initState).forEach(([key, value]) => {
        expect(memoizedState).toHaveProperty(key, value);
      });
      expect(memoizedState).toHaveProperty('test', '');
    });

    test('function initialState(paginationOptions) returns state with loading component when loading', () => {
      const paginationOptions = {
        needsTaskRequest: true,
      };
      const taskPagesApiEndpoint = 'https://example.com/api/taskPages?param=value';
      // Setup the test
      render(
        <QueueTable
          columns={columns}
          rowObjects={createTask(3)}
          summary={summary}
          slowReRendersAreOk
          defaultSort={{ test: '' }}
          useTaskPagesApi={true}
          paginationOptions={paginationOptions}
          taskPagesApiEndpoint={taskPagesApiEndpoint}
        />
      );

      const queueTable = screen.getByTestId('queue-table-data-testid');
      const fiberNode = getFiberNode(queueTable);
      const extractedData = extractPropsAndState(fiberNode);
      const memoizedState = extractedData.memoizedState;

      // Assertions
      Object.entries(initState).forEach(([key, value]) => {
        if (key !== 'loadingComponent') {
          expect(memoizedState).toHaveProperty(key, value);
        }
      });

      const { props: { spinnerColor } } = memoizedState.loadingComponent;
      expect(spinnerColor).toBe(LOGO_COLORS.QUEUE.ACCENT);

      expect(memoizedState).toHaveProperty('needsTaskRequest', true);
      expect(memoizedState).toHaveProperty('test', '');
    });
  });

  describe('render()', () => {
    test('Matches snapshot with default props', () => {
      // Setup the test
      const {container, asFragment} = render(
        <QueueTable columns={columns} rowObjects={createTask(3)} summary={summary} slowReRendersAreOk />
      );

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(container.querySelector('thead')).toBeInTheDocument();
      expect(container.querySelector('tbody')).toBeInTheDocument();
      expect(container.querySelector('tfoot')).toBeInTheDocument();

      // // Negative tests
      expect(screen.queryByTestId('table-filter-testid')).not.toBeInTheDocument();
      expect(container.querySelector('.table-icon')).not.toBeInTheDocument();
    });

    test('Renders pagination when set', () => {
      // Setup the test
      const { container, asFragment} = render(
        <QueueTable
          enablePagination
          columns={columns}
          rowObjects={createTask(20)}
          summary={summary}
          slowReRendersAreOk
        />
      );

      // Assertions
      expect(asFragment()).toMatchSnapshot();

      const pagination = container.querySelectorAll('.cf-pagination');
      expect(pagination).toHaveLength(2);

      const rows = [];
      for (let rowId = 0; rowId <= 14; rowId++) {
        const rowElement = container.querySelector(`#table-row-${rowId}`);
        rows.push(rowElement);
        expect(rowElement).toBeInTheDocument();
      }
      expect(rows).toHaveLength(15);
      expect(screen.getAllByText('Viewing 1-15 of 20 total')).not.toBeNull();

      // Change the page
      const nextButton = screen.getAllByRole('button', { name: 'Next Page' });
      fireEvent.click(nextButton[0]);

      const rows2 = [];
      for (let rowId = 0; rowId <= 4; rowId++) {
        const rowElement = container.querySelector(`#table-row-${rowId}`);
        rows2.push(rowElement);
        expect(rowElement).toBeInTheDocument();
        }
      expect(rows2).toHaveLength(5);
      expect(screen.getAllByText('Viewing 16-20 of 20 total')).not.toBeNull();
    });

    test('Renders loading component instead of body when loading data', () => {
      // Setup the test
      const useTaskPagesApi = true;
      const paginationOptions = {
        needsTaskRequest: true,
      };
      const taskPagesApiEndpoint = 'https://example.com/api/taskPages?param=value';

      const { container, asFragment} = render(
        <QueueTable
        enablePagination
        columns={columns}
        rowObjects={createTask(20)}
        summary={summary}
        slowReRendersAreOk
        useTaskPagesApi={useTaskPagesApi}
        paginationOptions={paginationOptions}
        taskPagesApiEndpoint={taskPagesApiEndpoint}
        />
      );

      // // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(container.querySelector('thead')).not.toBeInTheDocument();
      expect(container.querySelector('tbody')).not.toBeInTheDocument();
      expect(container.querySelector('tfoot')).not.toBeInTheDocument();
      expect(container.querySelector('.cf-loading-button-symbol')).toBeInTheDocument();
      expect(container.querySelector('.cf-react-icon-loading-front')).toBeInTheDocument();
      expect(container.querySelector('.cf-react-icon-loading-back')).toBeInTheDocument();
    });

    test('Can sort rows', () => {
      // Setup the test
      const {container, asFragment} = render(
        <QueueTable columns={sortColumns} rowObjects={tableData} summary={summary} slowReRendersAreOk />
      );

      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(container.querySelector('.table-icon')).toBeInTheDocument();

      const thirdColumn = screen.getByRole('columnheader', { name: 'Third' });
      expect(thirdColumn).toBeInTheDocument();
      expect(thirdColumn.getAttribute('aria-sort')).toBeNull();

      const sortByThird = screen.getByRole('button', { name: 'Sort by Third' });
      fireEvent.click(sortByThird);
      expect(thirdColumn.getAttribute('aria-sort')).toEqual('descending');

      fireEvent.click(sortByThird);
      expect(thirdColumn.getAttribute('aria-sort')).toEqual('ascending');

      fireEvent.click(sortByThird);
      expect(thirdColumn.getAttribute('aria-sort')).toEqual('descending');
    });

    test('Can filter rows', () => {
      // Setup the test
      const { container, asFragment} = render(
        <QueueTable columns={filterColumns} rowObjects={tableData} summary={summary} slowReRendersAreOk />
      );

      const filterButton = screen.getByRole('button');
      // Assertions
      expect(asFragment()).toMatchSnapshot();
      expect(screen.getByTestId('table-filter-testid')).toBeInTheDocument();
      expect(filterButton).toBeInTheDocument();
      expect(container.querySelector('.cf-dropdown-filter')).toBeNull();
      expect(screen.queryAllByRole('checkbox')).toHaveLength(0);

      fireEvent.click(filterButton);

      expect(container.querySelector('.cf-dropdown-filter')).toBeInTheDocument();
      expect(screen.queryAllByRole('checkbox')).toHaveLength(3);
    });
  });

  describe('DatePicker filter', () => {
    const records = [
      { id: 1, date: '5/1/2024' },
      { id: 2, date: '5/2/2024' },
      { id: 3, date: '5/3/2024' },
      { id: 4, date: '5/4/2024' },
      { id: 5, date: '5/5/2024' },
      { id: 6, date: '5/6/2024' },
      { id: 7, date: '5/7/2024' },
      { id: 8, date: '5/8/2024' },
      { id: 9, date: '5/9/2024' },
      { id: 10, date: '5/10/2024' },
      { id: 11, date: '5/11/2024' },
      { id: 12, date: '5/12/2024' },
      { id: 13, date: '5/13/2024' },
      { id: 14, date: '5/14/2024' },
      { id: 15, date: '5/15/2024' },
      { id: 16, date: '5/16/2024' },
      { id: 17, date: '5/17/2024' },
      { id: 18, date: '5/18/2024' },
      { id: 19, date: '5/19/2024' },
      { id: 20, date: '5/20/2024' }
    ];

    const columns = [{
      header: 'ID',
      name: 'id',
      enableFilter: false,
      anyFiltersAreSet: false,
      label: 'filter by id',
      columnName: 'id',
      valueName: 'ID',
      valueFunction: (row) => row.id,
      getSortValue: (row) => row.id
    }, {
      header: 'Date',
      name: 'date',
      enableFilter: true,
      anyFiltersAreSet: true,
      label: 'filter by date',
      columnName: 'date',
      tableData: records,
      valueName: 'Date',
      valueFunction: (row) => row.date,
      getSortValue: (row) => row.date,
      filterType: 'date-picker',
      filterSettings: {
        buttons: false,
        position: 'left'
      },
      customFilterMethod: datePickerFilterValue
    }];

    const openFilter = async (container) => {
      const svg = container.querySelectorAll('svg');

      const filter = svg[svg.length - 1];

      fireEvent.click(filter);
      await waitFor(() => {
        expect(screen.getByText('Date filter parameters')).toBeInTheDocument();
      });
    };

    const getTableDates = (container) => {
      const tds = container.querySelectorAll('td');
      let dates = [];

      for (let i = 0; i < tds.length; i += 2) {
        dates.push(tds[i + 1].innerHTML.trim());
      }

      return dates;
    };

    describe('Front end filtering', () => {

      const setupFrontend = () => {

        return render(<QueueTable
          columns={columns}
          rowObjects={records}
          enablePagination
          casesPerPage={15}
          anyFiltersAreSet
          getKeyForRow={(_, row) => row.id}
          defaultSort={{
            sortColName: 'id',
            sortAscending: true
          }}
        />);
      };

      it('renders in a queue table correctly', async () => {
        const { container } = setupFrontend();

        openFilter(container);

        expect(container).toMatchSnapshot();

      });

      it('filters between dates', async () => {
        const { container } = setupFrontend();

        expect(screen.getAllByText('Viewing 1-15 of 20 total')[0]).toBeInTheDocument();

        openFilter(container);

        selectFromDropdown('Date filter parameters', 'Between these dates');

        enterInputValue('start-date', '2024-05-01');
        enterInputValue('end-date', '2024-05-10');

        clickSubmissionButton('Apply Filter');

        expect(screen.getAllByText('Viewing 1-10 of 10 total')[0]).toBeInTheDocument();

        expect(getTableDates(container)).toEqual([
          '5/1/2024',
          '5/2/2024',
          '5/3/2024',
          '5/4/2024',
          '5/5/2024',
          '5/6/2024',
          '5/7/2024',
          '5/8/2024',
          '5/9/2024',
          '5/10/2024'
        ]);
      });

      it('filters before date', async () => {
        const { container } = setupFrontend();

        expect(screen.getAllByText('Viewing 1-15 of 20 total')[0]).toBeInTheDocument();

        openFilter(container);

        selectFromDropdown('Date filter parameters', 'Before this date');

        enterInputValue('start-date', '2024-05-10');

        clickSubmissionButton('Apply Filter');

        expect(screen.getAllByText('Viewing 1-9 of 9 total')[0]).toBeInTheDocument();

        expect(getTableDates(container)).toEqual([
          '5/1/2024',
          '5/2/2024',
          '5/3/2024',
          '5/4/2024',
          '5/5/2024',
          '5/6/2024',
          '5/7/2024',
          '5/8/2024',
          '5/9/2024'
        ]);
      });

      it('filters after date', async () => {
        const { container } = setupFrontend();

        expect(screen.getAllByText('Viewing 1-15 of 20 total')[0]).toBeInTheDocument();

        openFilter(container);

        selectFromDropdown('Date filter parameters', 'After this date');

        enterInputValue('start-date', '2024-05-15');

        clickSubmissionButton('Apply Filter');

        expect(screen.getAllByText('Viewing 1-5 of 5 total')[0]).toBeInTheDocument();

        expect(getTableDates(container)).toEqual([
          '5/16/2024',
          '5/17/2024',
          '5/18/2024',
          '5/19/2024',
          '5/20/2024'
        ]);
      });

      it('filters on date', async () => {
        const { container } = setupFrontend();

        expect(screen.getAllByText('Viewing 1-15 of 20 total')[0]).toBeInTheDocument();

        openFilter(container);

        selectFromDropdown('Date filter parameters', 'On this date');

        enterInputValue('start-date', '2024-05-15');

        clickSubmissionButton('Apply Filter');

        expect(screen.getAllByText('Viewing 1-1 of 1 total')[0]).toBeInTheDocument();

        expect(getTableDates(container)).toEqual([
          '5/15/2024'
        ]);
      });

      it('allows the filter to be cleared', async () => {
        const { container } = setupFrontend();

        expect(screen.getAllByText('Viewing 1-15 of 20 total')[0]).toBeInTheDocument();

        openFilter(container);

        selectFromDropdown('Date filter parameters', 'On this date');

        enterInputValue('start-date', '2024-05-15');

        clickSubmissionButton('Apply Filter');

        expect(screen.getAllByText('Viewing 1-1 of 1 total')[0]).toBeInTheDocument();

        openFilter(container);

        clickSubmissionButton('Clear filter');

        expect(screen.getAllByText('Viewing 1-15 of 20 total')[0]).toBeInTheDocument();
      });

    });

    describe('Back end filtering', () => {
      beforeEach(async () => {
        ApiUtil.get = jest.fn();

        when(ApiUtil.get).calledWith('/example/endpoint?&page=1').
          mockResolvedValue(({
            body: {
              task_page_count: 1,
              tasks: {
                data: [
                  records[0],
                  records[1],
                  records[2],
                  records[3],
                  records[4]
                ]
              },
              tasks_per_page: 15,
              total_task_count: 5
            }
          }));

        when(ApiUtil.get).calledWith('/example/endpoint?&page=1&filter%5B%5D=col%3Ddate%26val%3Don%2C2024-05-15%2C').
          mockResolvedValue(({
            body: {
              task_page_count: 1,
              tasks: {
                data: [
                  records[0],
                  records[1],
                  records[2]
                ]
              },
              tasks_per_page: 15,
              total_task_count: 3
            }
          }));

      });

      afterEach(() => {
        cleanup();
        jest.clearAllMocks();
      });

      const getUrlParams = (query) =>
        Array.from(new URLSearchParams(query)).reduce((pValue, [kValue, vValue]) =>
          Object.assign({}, pValue, {
            [kValue]: pValue[kValue] ? (Array.isArray(pValue[kValue]) ?
              pValue[kValue] : [pValue[kValue]]).concat(vValue) : vValue
          }), {});

      const setupBackend = () => {
        return render(<QueueTable
          columns={columns}
          rowObjects={[]}
          enablePagination
          casesPerPage={15}
          useTaskPagesApi
          taskPagesApiEndpoint={`/example/endpoint${encodeQueryParams()}`}
          anyFiltersAreSet
          tabPaginationOptions={getUrlParams(window.location.search)}
          getKeyForRow={(_, row) => row.id}
          skipCache
        />
        );
      };

      it('renders in a queue table correctly', async () => {
        const { container } = setupBackend();

        await waitFor(() =>
          expect(screen.getAllByText('Viewing 1-5 of 5 total')[0]).toBeInTheDocument()
        );

        openFilter(container);

        expect(container).toMatchSnapshot();

      });

      it('updates url params correctly on apply and reset', async () => {
        const { container } = setupBackend();

        expect(ApiUtil.get).toHaveBeenCalledWith('/example/endpoint?&page=1');

        await waitFor(() =>
          expect(screen.getAllByText('Viewing 1-5 of 5 total')[0]).toBeInTheDocument()
        );

        openFilter(container);

        selectFromDropdown('Date filter parameters', 'On this date');

        enterInputValue('start-date', '2024-05-15');

        clickSubmissionButton('Apply Filter');

        expect(ApiUtil.get).toHaveBeenCalledWith(
          '/example/endpoint?&page=1&filter%5B%5D=col%3Ddate%26val%3Don%2C2024-05-15%2C');

        await waitFor(() =>
          expect(screen.getAllByText('Viewing 1-3 of 3 total')[0]).toBeInTheDocument()
        );

        openFilter(container);

        clickSubmissionButton('Clear filter');

        expect(ApiUtil.get).toHaveBeenLastCalledWith('/example/endpoint?&page=1');

      });

    });
  });

});
