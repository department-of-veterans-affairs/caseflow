import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';

import {
  selectFromDropdown,
  clickSubmissionButton,
  enterInputValue
} from '../queue/components/modalUtils';

import { axe } from 'jest-axe';

import DatePicker, { datePickerFilterValue } from 'app/components/DatePicker';
import QueueTable from 'app/queue/QueueTable';

describe('DatePicker', () => {
  const handleChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = (props = {}) => {
    return render(<DatePicker
      label="date-picker"
      onChange={handleChange} {...props}
    />);
  };

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

  it('renders default state correctly', async () => {
    const { container } = setup();

    openFilter(container);

    expect(container).toMatchSnapshot();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('restores input values correctly', async () => {
    const { container } = setup({ values: ['between,2020-05-14,2024-01-17'] });

    openFilter(container);

    expect(container).toMatchSnapshot();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('shows one date field for before mode', async () => {
    const { container } = setup({ values: ['before,2020-05-14,'] });

    openFilter(container);

    expect(container).toMatchSnapshot();
  });

  it('shows one date field for after mode', async () => {
    const { container } = setup({ values: ['after,2020-05-14,'] });

    openFilter(container);

    expect(container).toMatchSnapshot();
  });

  it('shows one date field for on mode', async () => {
    const { container } = setup({ values: ['on,2020-05-14,'] });

    openFilter(container);

    expect(container).toMatchSnapshot();
  });

  it('allows dates to be input and form submitted', async () => {
    const { container } = setup();

    openFilter(container);

    selectFromDropdown('Date filter parameters', 'Between these dates');

    enterInputValue('start-date', '2020-05-14');
    enterInputValue('end-date', '2024-01-17');

    clickSubmissionButton('Apply Filter');

    expect(handleChange).toHaveBeenCalledWith('between,2020-05-14,2024-01-17');
  });

  it('allows the filter to be cleared', async () => {
    const { container } = setup({ values: ['on,2020-05-14,'] });

    openFilter(container);

    clickSubmissionButton('Clear filter');

    expect(handleChange).toHaveBeenCalledWith('');
  });

  describe('Front end filtering', () => {

    const setupFrontend = () => {

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
});
