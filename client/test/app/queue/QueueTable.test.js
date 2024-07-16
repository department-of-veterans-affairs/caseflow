import React from 'react';
import * as queueTable from 'app/queue/QueueTable';
import FilterSummary from 'app/components/FilterSummary';
import { shallow, mount } from 'enzyme';
import { render, screen, fireEvent, waitFor, logRoles } from '@testing-library/react';
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
import { get, times } from 'lodash';
import LoadingScreen from 'app/components/LoadingScreen';
import Pagination from 'app/components/Pagination/Pagination';
import { log } from 'console';

jest.mock('classnames');

jest.mock('app/util/ApiUtil', () => ({
  get: jest.fn().mockResolvedValue({})
}));

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
      const {container, asFragment} = render(
        <QueueTable columns={columns} rowObjects={createTask(3)} summary={summary} slowReRendersAreOk />
      );
      // screen.debug();
      logRoles(container)
      // Assertions
      // // expect(table).toMatchSnapshot();
      // expect(table.find(HeaderRow)).toHaveLength(1);
      expect(container.querySelector('thead')).toBeInTheDocument();

      // expect(table.find(BodyRows)).toHaveLength(1);
      expect(container.querySelector('tbody')).toBeInTheDocument();

      // expect(table.find(FooterRow)).toHaveLength(1);
      expect(container.querySelector('tfoot')).toBeInTheDocument();

      // expect(table.find(FilterSummary)).toHaveLength(1);

      // // Negative tests
      // expect(table.find(TableFilter)).toHaveLength(0);
      // expect(table.find(DoubleArrowIcon)).toHaveLength(0);
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
      // expect(table).toMatchSnapshot();
      // expect(asFragment()).toMatchSnapshot();

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
      // expect(table).toMatchSnapshot();
      // expect(asFragment()).toMatchSnapshot();

      expect(container.querySelector('thead')).not.toBeInTheDocument();
      expect(container.querySelector('tbody')).not.toBeInTheDocument();
      expect(container.querySelector('tfoot')).not.toBeInTheDocument();
      expect(container.querySelector('.cf-loading-button-symbol')).toBeInTheDocument();
      expect(container.querySelector('.cf-react-icon-loading-front')).toBeInTheDocument();
      expect(container.querySelector('.cf-react-icon-loading-back')).toBeInTheDocument();
    });

    test.only('Can sort rows', () => {
      // Setup the test
      const { container, asFragment} = render(
        <QueueTable columns={sortColumns} rowObjects={tableData} summary={summary} slowReRendersAreOk />
      );

      // Assertions
      // expect(table).toMatchSnapshot();
      // expect(asFragment()).toMatchSnapshot();

      // screen.debug();
      // logRoles(container)
      // expect(table.state('sortColName')).toEqual(null);
      // expect(table.state('sortAscending')).toEqual(true);

      let ariaSort = container.querySelector('aria-sort')
      console.log(ariaSort);
      const sortByThird = screen.getByRole('button', { name: 'Sort by Third' });
      fireEvent.click(sortByThird);
      ariaSort = container.querySelector('th').getAttribute('aria-sort');
      console.log(ariaSort);


      fireEvent.click(sortByThird);
      // console.log(ariaSort);
      fireEvent.click(sortByThird);
      // console.log(ariaSort);
      // // Simulate sorting the table
      // table.find({ 'aria-label': 'Sort by Third' }).simulate('click');
      // expect(table.state('sortColName')).toEqual('type');
      // expect(table.state('sortAscending')).toEqual(false);

      // // Update the sorting again
      // table.find({ 'aria-label': 'Sort by Third' }).simulate('click');
      // expect(table.state('sortColName')).toEqual('type');
      // expect(table.state('sortAscending')).toEqual(true);
    });

    test('Can filter rows', () => {
      // Setup the test
      const { container, asFragment} = render(
        <QueueTable columns={filterColumns} rowObjects={tableData} summary={summary} slowReRendersAreOk />
      );

      // Assertions
      expect(table).toMatchSnapshot();
      expect(table.state('filterByList')).toEqual(undefined);
    });
  });
});
