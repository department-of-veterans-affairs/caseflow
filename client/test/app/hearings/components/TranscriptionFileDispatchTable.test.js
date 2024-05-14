import React from 'react';
import { screen, render, fireEvent, within } from '@testing-library/react';
import { axe } from 'jest-axe';
import { TranscriptionFileDispatchTable } from '../../../../app/hearings/components/TranscriptionFileDispatchTable';
import TRANSCRIPTION_FILE_DISPATCH_CONFIG from '../../../../constants/TRANSCRIPTION_FILE_DISPATCH_CONFIG';
import { unassignedColumns } from '../../../../app/hearings/components/TranscriptionFileDispatchTabs';

const setupUnassignedTable = () =>
  render(<TranscriptionFileDispatchTable columns={unassignedColumns(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)} />);

describe('TranscriptionFileDispatchTable', () => {
  describe('UnassignedTab', () => {
    it('Select all column is rendered', () => {
      const { container } = setupUnassignedTable();
      const checkboxes = container.querySelectorAll('.cf-form-checkbox');

      expect(screen.getByText('Select All')).toBeInTheDocument();
      expect(checkboxes.length).toBe(16);
    });

    it('Docket number column is rendered', () => {
      setupUnassignedTable();

      expect(screen.getByText('Docket Number')).toBeInTheDocument();
    });

    it('Case details column is rendered', () => {
      setupUnassignedTable();

      expect(screen.getByText('Case Details')).toBeInTheDocument();
    });

    it('Types column is rendered', () => {
      setupUnassignedTable();

      expect(screen.getByText('Types')).toBeInTheDocument();
    });

    it('Types column is sortable', () => {
      setupUnassignedTable();
      const typeHeader = document.querySelector('[aria-labelledby="header-type"]');
      const sorter = typeHeader.querySelector('svg.table-icon');
      const firstRow = document.querySelectorAll('tr')[1];

      const { getByText } = within(firstRow);

      fireEvent.click(sorter);
      expect(getByText('Original')).toBeInTheDocument();

      fireEvent.click(sorter);
      expect(getByText('AOD')).toBeInTheDocument();
    });

    it('Types column is filterable', () => {
      setupUnassignedTable();
      const typeHeader = document.querySelector('[aria-labelledby="header-type"]');
      const filter = typeHeader.querySelector('svg.unselected-filter-icon');
      const firstRow = document.querySelectorAll('tr')[1];

      const { getByText } = within(firstRow);

      fireEvent.click(filter);
      const option = screen.getByText('Aod (4)');

      fireEvent.click(option);
      expect(getByText('AOD')).toBeInTheDocument();
    });

    it('Hearing Date column is rendered', () => {
      setupUnassignedTable();

      expect(screen.getByText('Hearing Date')).toBeInTheDocument();
    });

    it('Hearing Date is sortable', () => {
      setupUnassignedTable();
      const typeHeader = document.querySelector('[aria-labelledby="header-hearingDate"]');
      const sorter = typeHeader.querySelector('svg.table-icon');
      const firstRow = document.querySelectorAll('tr')[1];

      const { getByText } = within(firstRow);

      fireEvent.click(sorter);
      expect(getByText('5/20/2024')).toBeInTheDocument();

      fireEvent.click(sorter);
      expect(getByText('5/08/2024')).toBeInTheDocument();
    });

    it('Hearing Type column is rendered', () => {
      setupUnassignedTable();

      expect(screen.getByText('Hearing Type')).toBeInTheDocument();
    });

    it('Hearing Type column is filterable', () => {
      setupUnassignedTable();
      const typeHeader = document.querySelector('[aria-labelledby="header-hearingType"]');
      const filter = typeHeader.querySelector('svg.unselected-filter-icon');
      const firstRow = document.querySelectorAll('tr')[1];

      const { getByText } = within(firstRow);

      fireEvent.click(filter);
      const option = screen.getByText('Legacy (8)');

      fireEvent.click(option);
      expect(getByText('Legacy')).toBeInTheDocument();
    });

    it('Status column is rendered', () => {
      setupUnassignedTable();

      expect(screen.getByText('Status')).toBeInTheDocument();
    });

    it('Status column is filterable', () => {
      setupUnassignedTable();
      const typeHeader = document.querySelector('[aria-labelledby="header-status"]');
      const filter = typeHeader.querySelector('svg.unselected-filter-icon');
      const firstRow = document.querySelectorAll('tr')[1];

      const { getByText } = within(firstRow);

      fireEvent.click(filter);
      const option = screen.getByText('Completed (4)');

      fireEvent.click(option);
      expect(getByText('Completed')).toBeInTheDocument();
    });

    it('matches snaphot', () => {
      const { container } = setupUnassignedTable();

      expect(container).toMatchSnapshot();
    });

    it('passes a11y', async () => {
      const { container } = setupUnassignedTable();
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });
});
