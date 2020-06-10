import React from 'react';
import * as queueTable from 'app/queue/QueueTable';
import FilterSummary from 'app/components/FilterSummary';
import { shallow } from 'enzyme';
import { columns, createTask, summary, headerStyle, iconStyle } from 'test/data';
import Tooltip from 'app/components/Tooltip';
import { DoubleArrow } from 'app/components/RenderFunctions';
import TableFilter from 'app/components/TableFilter';
import { COLORS, LOGO_COLORS } from 'app/constants/AppConstants';
import * as glamor from 'glamor';
import classnames from 'classnames';

jest.mock('classnames');

const { default: QueueTable, HeaderRow, BodyRows, FooterRow } = queueTable;

const ColumnContent = ({ label, filter, sort, filterProps, headerStyle, iconStyle }) => (
  <span {...headerStyle}>
    <span>{label}</span>
    {sort && (
      <span {...iconStyle} aria-label={`Sort by ${label}`} role="button" tabIndex="0">
        <DoubleArrow />
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

    test('function getCellValue(rowObject, rowId, column) returns value function when set on column', () => {});

    test('function getCellValue(rowObject, rowId, column) returns value name when set on column', () => {});

    test('function getCellValue(rowObject, rowId, column) returns empty when neither function nor name are set on column', () => {});

    test('function getCellSpan(rowObject, column) returns valueFunction results when present on column', () => {});

    test('function getCellSpan(rowObject, column) returns 1 if valueFunciton is not present on column', () => {});
  });

  describe('HeaderRow', () => {
    beforeEach(() => {
      // Mock the CSS Module
      jest.spyOn(glamor, 'css');
      jest.spyOn(glamor, 'hover');
    });

    afterEach(() => {
      jest.restoreAllMocks();
    });

    test('Matches snapshot with default props', () => {
      // Setup the test
      glamor.css.mockReturnValueOnce(headerStyle);
      glamor.hover.mockReturnValue('test-class');
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

    test('Can sort when not using the tasks API and getting column sort value', () => {});

    test('Can sort when the backend can sort and getting column sort value', () => {});

    test('Can filter when not using task pages API and filtering is enabled', () => {});

    test('Can filter when not using task pages API and getting filter values', () => {});

    test('Can filter when using task pages API and column has filter options', () => {});

    test('Renders tooltip when present on the column', () => {});
  });

  describe('Row', () => {});

  describe('BodyRows', () => {});

  describe('FooterRow', () => {});

  describe('Class Methods', () => {});

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
      expect(table.find(DoubleArrow)).toHaveLength(0);
    });
  });
});
