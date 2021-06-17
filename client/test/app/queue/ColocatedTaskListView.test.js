import React from 'react';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import { ColocatedTaskListView } from 'app/queue/ColocatedTaskListView';
import ReduxBase from 'app/components/ReduxBase';
import {
  completedHoldTask,
  daysOnHold,
  noOnHoldDurationTask,
  getQueueConfig,
  taskNewAssigned,
  taskOnHold,
} from 'test/data/queue/taskLists';
import reducer, { initialState } from 'app/queue/reducers';
import { MemoryRouter } from 'react-router';

// eslint-disable-next-line react/prop-types
const WrapperComponent = ({ children }) => (
  <MemoryRouter>
    <ReduxBase
      reducer={reducer}
      initialState={{
        queue: { ...initialState, queueConfig: { ...getQueueConfig() } },
      }}
    >
      {children}
    </ReduxBase>
  </MemoryRouter>
);

// Date constructor uses zero-based offset for months — this is 2021-03-17
const fakeDate = new Date(2021, 2, 17, 12);

beforeAll(() => {
  // Ensure consistent handling of dates across tests
  jest.useFakeTimers('modern');
  jest.setSystemTime(fakeDate);
});

afterAll(() => {
  // Reset normal timers
  jest.useRealTimers();
});

describe('ColocatedTaskListView', () => {
  const clearCaseSelectSearch = jest.fn();
  const hideSuccessMessage = jest.fn();
  const defaults = { clearCaseSelectSearch, hideSuccessMessage };
  const setup = (props = {}) =>
    render(<ColocatedTaskListView {...defaults} {...props} />, {
      wrapper: WrapperComponent,
    });

  describe('assigned tab', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    it('passes a11y', async () => {
      // Fake timers causes timeouts for jest-axe
      jest.useRealTimers();

      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();

      jest.useFakeTimers('modern');
    });

    it('shows only new tasks and tasks with a completed hold', async () => {
      setup();

      const task1 = taskNewAssigned().attributes;
      const task2 = completedHoldTask().attributes;

      await waitFor(() => {
        expect(
          screen.getByRole('cell', {
            name: new RegExp(task1.veteran_file_number, 'i'),
          })
        ).toBeInTheDocument();
        expect(
          screen.getByRole('cell', {
            name: new RegExp(task2.veteran_file_number, 'i'),
          })
        ).toBeInTheDocument();
      });
    });

    it('displays the correct info for newly assigned task', () => {
      setup();

      const task = taskNewAssigned().attributes;

      const row = screen.getByRole('row', {
        name: new RegExp(task.veteran_file_number, 'i'),
      });
      const cells = within(row).getAllByRole('cell');

      const [
        hearings,
        caseDetails,
        columnTasks,
        types,
        docketNumber,
        numberDaysOnHold,
        documents,
      ] = cells;

      expect(
        within(caseDetails).getByText(new RegExp(task.veteran_full_name, 'i'))
      ).toBeInTheDocument();
      expect(
        within(caseDetails).getByText(new RegExp(task.veteran_file_number, 'i'))
      ).toBeInTheDocument();

      expect(within(columnTasks).getByText(task.label)).toBeInTheDocument();

      expect(within(types).getByText(task.case_type)).toBeInTheDocument();

      expect(
        within(docketNumber).getByText(task.docket_number)
      ).toBeInTheDocument();

      expect(within(numberDaysOnHold).getByText('1 day')).toBeInTheDocument();

      expect(
        within(documents).getByRole('link', { name: /view docs/i })
      ).toHaveAttribute(
        'href',
        expect.stringContaining(
          `/reader/appeal/${task.external_appeal_id}/documents`
        )
      );

      expect(
        within(documents).getByText(/Loading number of docs/i)
      ).toBeInTheDocument();
    });

    it('shows the correct info for the completed hold task', async () => {
      setup();

      const task = completedHoldTask().attributes;

      const row = screen.getByRole('row', {
        name: new RegExp(task.veteran_file_number, 'i'),
      });
      const cells = within(row).getAllByRole('cell');

      const numberDaysOnHold = cells[5];

      expect(within(numberDaysOnHold).getByText('31 days')).toBeInTheDocument();

      expect(numberDaysOnHold.lastChild.lastChild).toHaveClass(
        'cf-continuous-progress-bar'
      );
    });
  });

  describe('on hold tab', () => {
    it('renders correctly', async () => {
      const { container } = setup();

      const task1 = taskOnHold().attributes;

      // Switch to the appropriate tab
      await userEvent.click(screen.getByRole('tab', { name: /on hold/i }));

      // Wait for new content to appear
      await waitFor(() => {
        expect(
          screen.getByRole('cell', {
            name: new RegExp(task1.veteran_file_number, 'i'),
          })
        ).toBeInTheDocument();
      });

      expect(container).toMatchSnapshot();
    });

    it('passes a11y', async () => {
      // Fake timers causes timeouts for jest-axe
      jest.useRealTimers();

      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();

      jest.useFakeTimers('modern');
    });

    it('shows only on-hold tasks', async () => {
      setup();

      const task1 = taskOnHold().attributes;
      const task2 = noOnHoldDurationTask().attributes;

      // Switch to the appropriate tab
      await userEvent.click(screen.getByRole('tab', { name: /on hold/i }));

      // Wait for new content to appear
      await waitFor(() => {
        expect(
          screen.getByRole('cell', {
            name: new RegExp(task1.veteran_file_number, 'i'),
          })
        ).toBeInTheDocument();
        expect(
          screen.getByRole('cell', {
            name: new RegExp(task2.veteran_file_number, 'i'),
          })
        ).toBeInTheDocument();
      });
    });

    it('displays correct info for on-hold task', async () => {
      setup();

      // Switch to the appropriate tab
      await userEvent.click(screen.getByRole('tab', { name: /on hold/i }));

      const task = taskOnHold().attributes;

      await waitFor(() => {
        expect(
          screen.getByRole('row', {
            name: new RegExp(task.veteran_file_number, 'i'),
          })
        ).toBeInTheDocument();
      });

      const row = screen.getByRole('row', {
        name: new RegExp(task.veteran_file_number, 'i'),
      });

      const cells = within(row).getAllByRole('cell');

      const [
        hearings,
        caseDetails,
        columnTasks,
        types,
        docketNumber,
        numberDaysOnHold,
        documents,
      ] = cells;

      expect(
        within(caseDetails).getByText(new RegExp(task.veteran_full_name, 'i'))
      ).toBeInTheDocument();
      expect(
        within(caseDetails).getByText(new RegExp(task.veteran_file_number, 'i'))
      ).toBeInTheDocument();

      expect(within(columnTasks).getByText(task.label)).toBeInTheDocument();

      expect(within(types).getByText(task.case_type)).toBeInTheDocument();

      expect(
        within(docketNumber).getByText(task.docket_number)
      ).toBeInTheDocument();

      expect(
        within(numberDaysOnHold).getByText(`1 of ${daysOnHold}`)
      ).toBeInTheDocument();
      expect(numberDaysOnHold.lastChild).toHaveClass(
        'cf-continuous-progress-bar'
      );

      expect(
        within(documents).getByRole('link', { name: /view docs/i })
      ).toHaveAttribute(
        'href',
        expect.stringContaining(
          `/reader/appeal/${task.external_appeal_id}/documents`
        )
      );

      expect(
        within(documents).getByText(/Loading number of docs/i)
      ).toBeInTheDocument();
    });

    it('shows the correct info for the on-hold task with no duration', async () => {
      setup();

      const task = noOnHoldDurationTask().attributes;

      // Switch to the appropriate tab
      await userEvent.click(screen.getByRole('tab', { name: /on hold/i }));

      await waitFor(() => {
        expect(
          screen.getByRole('row', {
            name: new RegExp(task.veteran_file_number, 'i'),
          })
        ).toBeInTheDocument();
      });

      const row = screen.getByRole('row', {
        name: new RegExp(task.veteran_file_number, 'i'),
      });
      const cells = within(row).getAllByRole('cell');

      const numberDaysOnHold = cells[5];

      expect(within(numberDaysOnHold).getByText('30')).toBeInTheDocument();

      expect(numberDaysOnHold.lastChild).toHaveClass(
        'cf-continuous-progress-bar'
      );
    });
  });
});
