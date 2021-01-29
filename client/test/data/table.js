export const columns = [
  { header: 'First', valueFunction: jest.fn().mockReturnValue('fizz'), span: jest.fn().mockReturnValue(2) },
  { header: 'Second', valueFunction: jest.fn().mockReturnValue('buzz') },
  { header: 'Second', valueName: 'type' }
];

export const summary = 'Example table summary';

export const headerStyle = { styleName: 'header' };

export const iconStyle = { styleName: 'icon' };

export const rowObject = { type: 'Something' };

export const rowId = 123;

export const initState = {
  cachedResponses: {},
  tasksFromApi: null,
  loadingComponent: undefined
};

export const baseColumns = [
  {
    header: 'First',
    valueName: 'one'
  },
  {
    header: 'Second',
    valueName: 'two'
  }
];

export const footerColumns = [
  ...baseColumns,
  {
    header: 'Second',
    valueName: 'two',
    footer: 'Some Footer'
  }
];

export const tableData = [
  {
    one: 'First column',
    two: 'Second column',
    type: 'Something'
  },
  {
    one: 'First column second row',
    two: 'Second column second row',
    type: 'Something Else'
  },
  {
    one: 'First column third row',
    two: 'Second column third row',
    type: 'EstablishClaim'
  }
];

export const sortColumns = [
  ...baseColumns,
  {
    header: 'Third',
    valueName: 'type',
    name: 'type',
    getSortValue: jest.fn().mockReturnValue(tableData[2].type)
  }
];

export const backendSortColumns = [
  ...baseColumns,
  {
    header: 'Third',
    valueName: 'type',
    name: 'type',
    backendCanSort: true,
    getSortValue: jest.fn().mockReturnValue(tableData[2].type)
  }
];

export const filterColumns = [
  ...baseColumns,
  {
    header: 'Third',
    valueName: 'type',
    columnName: 'type',
    enableFilter: true,
    tableData
  }
];

export const filterColumnsWithValues = [
  ...baseColumns,
  {
    header: 'Third',
    valueName: 'type',
    columnName: 'type',
    getFilterValues: jest.fn().mockReturnValue(true),
    tableData
  }
];

export const filterColumnsWithOptions = [
  ...baseColumns,
  {
    header: 'Third',
    valueName: 'type',
    columnName: 'type',
    enableFilter: true,
    filterOptions: [],
    tableData
  }
];

export const columnsWithTooltip = [
  ...baseColumns,
  {
    header: 'Third',
    valueName: 'type',
    name: 'type',
    tooltip: 'Some text'
  }
];
