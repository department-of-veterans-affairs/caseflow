/* eslint-disable max-lines */
import React from 'react';
import * as queueTable from 'app/queue/QueueTable';
import FilterSummary from 'app/components/FilterSummary';
import { shallow, mount } from 'enzyme';
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
import Tooltip from 'app/components/Tooltip';
import { DoubleArrowIcon } from 'app/components/icons/DoubleArrowIcon';
import TableFilter from 'app/components/TableFilter';
import { COLORS, LOGO_COLORS } from 'app/constants/AppConstants';
import * as glamor from 'glamor';
import classnames from 'classnames';
import { times } from 'lodash';
import LoadingScreen from 'app/components/LoadingScreen';
import Pagination from 'app/components/Pagination/Pagination';
import {
  selectFromDropdown,
  clickSubmissionButton,
  enterInputValue,
  openFilter
} from '../queue/components/modalUtils';
import { render, screen, waitFor, cleanup } from '@testing-library/react';
import { datePickerFilterValue } from 'app/components/DatePicker';
import { encodeQueryParams } from 'app/util/QueryParamsUtil';
import { when } from 'jest-when';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('classnames');

const { default: QueueTable, HeaderRow, BodyRows, FooterRow, Row } = queueTable;

const ColumnContent = ({ label, filter, sort, filterProps, headerStyle, iconStyle }) => (
  <span {...headerStyle}>
    <span>{label}</span>
    {sort && (
      <span {...iconStyle} aria-label={`Sort by ${label}`} role="button" tabIndex="0">
        <DoubleArrowIcon />
      </span>
    )}
    {filter && <TableFilter {...filterProps} />}
  </span>
);

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
      const header = shallow(<HeaderRow columns={columns} rowObjects={createTask(3)} />);

      // Assertions
      expect(header).toMatchSnapshot();
      expect(header.find('tr')).toHaveLength(1);
      expect(header.find('tr').prop('role')).toEqual('row');
      expect(header.find('th')).toHaveLength(3);

      // Test each header individually
      header.find('th').map((element, i) => {
        expect(element.prop('role')).toEqual('columnheader');
        expect(element.containsMatchingElement(ColumnContent({ label: columns[i].header, headerStyle }))).toEqual(true);
      });

      // Test the CSS classes
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
      const header = shallow(<HeaderRow setSortOrder={sortMock} columns={sortColumns} rowObjects={tableData} />);

      // Find the sort button
      header.
        find('tr').
        childAt(2).
        childAt(0).
        childAt(1).
        simulate('click');

      // Assertions
      expect(header).toMatchSnapshot();
      expect(header.find(DoubleArrowIcon)).toHaveLength(1);
      expect(sortMock).toHaveBeenCalledWith(sortColumns[2].name);

      // Test sorting colors
      expect(header.find(DoubleArrowIcon).prop('topColor')).toEqual(COLORS.GREY_LIGHT);
      expect(header.find(DoubleArrowIcon).prop('bottomColor')).toEqual(COLORS.GREY_LIGHT);

      // Test Ascending the sort order
      header.setProps({ sortColName: 'type', sortAscending: true });
      expect(header.find(DoubleArrowIcon).prop('topColor')).toEqual(COLORS.GREY_LIGHT);
      expect(header.find(DoubleArrowIcon).prop('bottomColor')).toEqual(COLORS.PRIMARY);

      // Test Descending the sort order
      header.setProps({ sortColName: 'type', sortAscending: false });
      expect(header.find(DoubleArrowIcon).prop('topColor')).toEqual(COLORS.PRIMARY);
      expect(header.find(DoubleArrowIcon).prop('bottomColor')).toEqual(COLORS.GREY_LIGHT);
    });

    test('Can sort when the backend can sort and getting column sort value', () => {
      // Setup the test
      const sortMock = jest.fn();

      // Run the test
      const header = shallow(
        <HeaderRow useTaskPagesApi setSortOrder={sortMock} columns={backendSortColumns} rowObjects={tableData} />
      );

      // Find the sort button
      header.
        find('tr').
        childAt(2).
        childAt(0).
        childAt(1).
        simulate('click');

      // Assertions
      expect(header).toMatchSnapshot();
      expect(header.find(DoubleArrowIcon)).toHaveLength(1);
      expect(sortMock).toHaveBeenCalledWith(backendSortColumns[2].name);

      // Test sorting colors
      expect(header.find(DoubleArrowIcon).prop('topColor')).toEqual(COLORS.GREY_LIGHT);
      expect(header.find(DoubleArrowIcon).prop('bottomColor')).toEqual(COLORS.GREY_LIGHT);

      // Test Ascending the sort order
      header.setProps({ sortColName: 'type', sortAscending: true });
      expect(header.find(DoubleArrowIcon).prop('topColor')).toEqual(COLORS.GREY_LIGHT);
      expect(header.find(DoubleArrowIcon).prop('bottomColor')).toEqual(COLORS.PRIMARY);

      // Test Descending the sort order
      header.setProps({ sortColName: 'type', sortAscending: false });
      expect(header.find(DoubleArrowIcon).prop('topColor')).toEqual(COLORS.PRIMARY);
      expect(header.find(DoubleArrowIcon).prop('bottomColor')).toEqual(COLORS.GREY_LIGHT);
    });

    test('Can filter when not using task pages API and filtering is enabled', () => {
      // Run the test
      const header = shallow(<HeaderRow columns={filterColumns} rowObjects={tableData} />);

      // Assertions
      expect(header).toMatchSnapshot();
      expect(header.find(TableFilter)).toHaveLength(1);
    });

    test('Can filter when not using task pages API and getting filter values', () => {
      // Run the test
      const header = shallow(<HeaderRow columns={filterColumnsWithValues} rowObjects={tableData} />);

      // Assertions
      expect(header).toMatchSnapshot();
      expect(header.find(TableFilter)).toHaveLength(1);
    });

    test('Can filter when using task pages API and column has filter options', () => {
      // Run the test
      const header = shallow(<HeaderRow useTaskPagesApi columns={filterColumnsWithOptions} rowObjects={tableData} />);

      // Assertions
      expect(header).toMatchSnapshot();
      expect(header.find(TableFilter)).toHaveLength(1);
    });

    test('Renders tooltip when present on the column', () => {
      // Run the test
      const header = shallow(<HeaderRow useTaskPagesApi columns={columnsWithTooltip} rowObjects={tableData} />);

      // Assertions
      expect(header).toMatchSnapshot();
      expect(header.find(Tooltip)).toHaveLength(1);
      expect(header.find(Tooltip).prop('text')).toEqual(columnsWithTooltip[2].tooltip);
    });
  });

  describe('Row', () => {
    test('Matches snapshot with default props', () => {
      // Setup the test
      const rowClassNames = jest.fn().mockReturnValue('test');

      // Run the test
      const row = shallow(
        <Row rowClassNames={rowClassNames} columns={baseColumns} rowObjects={tableData} rowObject={tableData[0]} />
      );

      // Assertions
      expect(row).toMatchSnapshot();
      expect(row.find('tr')).toHaveLength(1);
      expect(row.find('tr').prop('role')).toEqual('row');
      expect(row.find('td')).toHaveLength(2);

      // Test each cell individually
      row.find('td').map((element, i) => {
        expect(element.prop('role')).toEqual('gridcell');
        expect(element.text()).toEqual(tableData[0][baseColumns[i].valueName]);
      });
    });

    test('Renders footer when the column is set to a footer', () => {
      // Setup the test
      const rowClassNames = jest.fn().mockReturnValue('test');

      // Run the test
      const row = shallow(
        <Row
          footer
          rowClassNames={rowClassNames}
          columns={footerColumns}
          rowObjects={tableData}
          rowObject={tableData[2]}
        />
      );

      // Assertions
      expect(row).toMatchSnapshot();
      expect(
        row.
          find('tr').
          childAt(2).
          text()
      ).toEqual(footerColumns[2].footer);
    });
  });

  describe('BodyRows', () => {
    jest.spyOn(console, 'error').mockReturnValue();

    test('Matches snapshot with default props', () => {
      // Setup the test
      const getKeyForRow = jest.fn();

      // Run the test
      const body = shallow(<BodyRows getKeyForRow={getKeyForRow} columns={filterColumns} rowObjects={tableData} />);

      // Assertions
      expect(body).toMatchSnapshot();
      expect(body.find('tbody')).toHaveLength(1);
      expect(body.find(Row)).toHaveLength(3);
      times(tableData.length).map((index) => {
        expect(getKeyForRow).toHaveBeenNthCalledWith(index + 1, index, tableData[index]);
      });
    });
  });

  describe('FooterRow', () => {
    jest.spyOn(console, 'error').mockReturnValue();

    test('Matches snapshot with default props', () => {
      // Run the test
      const footer = shallow(<FooterRow columns={footerColumns} />);

      // Assertions
      expect(footer).toMatchSnapshot();
      expect(footer.find('tfoot')).toHaveLength(1);
      expect(footer.find(Row)).toHaveLength(1);
    });

    test('Renders no footer when not present in the column', () => {
      // Run the test
      const footer = shallow(<FooterRow columns={baseColumns} />);

      // Assertions
      expect(footer).toMatchSnapshot();
      expect(footer.find('tfoot')).toHaveLength(1);
      expect(footer.find(Row)).toHaveLength(0);
      expect(footer.children()).toHaveLength(0);
    });
  });

  describe('Class Methods', () => {
    let instance, table;

    beforeEach(() => {
      // Mount the component to test methods against
      table = shallow(<QueueTable columns={columns} rowObjects={createTask(3)} summary={summary} slowReRendersAreOk />);
      instance = table.instance();

      // Spy on the instance methods
      jest.spyOn(instance, 'initialState');
    });

    test('function initialState(paginationOptions) returns state', () => {
      // Run the test
      const result = instance.initialState();

      // Assertions
      expect(result).toEqual(initState);
    });

    test('function initialState(paginationOptions) returns state with default sort when set', () => {
      // Setup the test
      table.setProps({ defaultSort: { test: '' } });
      table.update();

      // Run the test
      const result = instance.initialState();

      // Assertions
      expect(result).toEqual({
        ...initState,
        test: ''
      });
    });

    test('function initialState(paginationOptions) returns state with loading component when loading', () => {
      // Setup the test
      table.setProps({ useTaskPagesApi: true });
      table.update();

      // Run the test
      const result = instance.initialState({ needsTaskRequest: true });

      // Assertions
      expect(result).toEqual({
        ...initState,
        needsTaskRequest: true,
        loadingComponent: <LoadingScreen spinnerColor={LOGO_COLORS.QUEUE.ACCENT} />
      });
    });
  });

  describe('render()', () => {
    test('Matches snapshot with default props', () => {
      // Setup the test
      const table = shallow(
        <QueueTable columns={columns} rowObjects={createTask(3)} summary={summary} slowReRendersAreOk />
      );

      // Assertions
      expect(table).toMatchSnapshot();
      expect(table.find(HeaderRow)).toHaveLength(1);
      expect(table.find(BodyRows)).toHaveLength(1);
      expect(table.find(FooterRow)).toHaveLength(1);
      expect(table.find(FilterSummary)).toHaveLength(1);

      // Negative tests
      expect(table.find(TableFilter)).toHaveLength(0);
      expect(table.find(DoubleArrowIcon)).toHaveLength(0);
    });

    test('Renders pagination when set', () => {
      // Setup the test
      const table = mount(
        <QueueTable
          enablePagination
          columns={columns}
          rowObjects={createTask(20)}
          summary={summary}
          slowReRendersAreOk
        />
      );

      // Assertions
      expect(table).toMatchSnapshot();
      expect(table.find(Pagination)).toHaveLength(2);
      expect(table.find(Row)).toHaveLength(15);
      expect(table.state('currentPage')).toEqual(0);

      // Change the page
      table.
        find('.cf-pagination-pages').
        first().
        childAt(3).
        simulate('click');
      expect(table.find(Row)).toHaveLength(5);
      expect(table.state('currentPage')).toEqual(1);
    });

    test('Renders loading component instead of body when loading data', () => {
      // Setup the test
      const table = mount(
        <QueueTable
          enablePagination
          columns={columns}
          rowObjects={createTask(20)}
          summary={summary}
          slowReRendersAreOk
        />
      );

      table.setState({ loadingComponent: <LoadingScreen /> });

      // Assertions
      expect(table).toMatchSnapshot();
      expect(table.find(HeaderRow)).toHaveLength(0);
      expect(table.find(BodyRows)).toHaveLength(0);
      expect(table.find(FooterRow)).toHaveLength(0);
      expect(table.find(LoadingScreen)).toHaveLength(1);
    });

    test('Can sort rows', () => {
      // Setup the test
      const table = mount(
        <QueueTable columns={sortColumns} rowObjects={tableData} summary={summary} slowReRendersAreOk />
      );

      // Assertions
      expect(table).toMatchSnapshot();
      expect(table.state('sortColName')).toEqual(null);
      expect(table.state('sortAscending')).toEqual(true);

      // Simulate sorting the table
      table.find({ 'aria-label': 'Sort by Third' }).simulate('click');
      expect(table.state('sortColName')).toEqual('type');
      expect(table.state('sortAscending')).toEqual(false);

      // Update the sorting again
      table.find({ 'aria-label': 'Sort by Third' }).simulate('click');
      expect(table.state('sortColName')).toEqual('type');
      expect(table.state('sortAscending')).toEqual(true);
    });

    test('Can filter rows', () => {
      // Setup the test
      const table = mount(
        <QueueTable columns={filterColumns} rowObjects={tableData} summary={summary} slowReRendersAreOk />
      );

      // Assertions
      expect(table).toMatchSnapshot();
      expect(table.state('filterByList')).toEqual(undefined);
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
        jest.spyOn(Date, 'now').mockReturnValue('2024-10-18T15:37:00.000-04:00');

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
