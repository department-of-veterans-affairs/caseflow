import React from 'react';
import { render, screen, within } from '@testing-library/react';
import selectEvent from 'react-select-event';
import { axe } from 'jest-axe';
import { MemoryRouter } from 'react-router';

import { OrgRow, priorityPushOpts, requestCasesOpts } from 'app/queue/teamManagement/OrgRow';
import { createJudgeTeam, createVso } from 'test/data/teamManagement';

describe('OrgRow', () => {
  const defaults = {};

  const setup = (props) =>
    render(<MemoryRouter><OrgRow {...defaults} {...props} /></MemoryRouter>);

  it('renders correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  describe('with JudgeTeam', () => {
    const judgeTeam = createJudgeTeam(1)[0];

    describe('without edit permissions', () => {
      const props = {
        ...judgeTeam,
        showDistributionToggles: true,
        current_user_can_toggle_priority_pushed_cases: false
      };

      it('renders correctly', () => {
        const { container } = setup(props);

        expect(container).toMatchSnapshot();
      });

      it('passes a11y testing', async () => {
        const { container } = setup(props);

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });

      it('prevents editing of dropdowns', async () => {
        setup(props);

        // Try to open menu
        await selectEvent.openMenu(screen.getByLabelText('priorityCaseDistribution-1'));

        ['AMA cases only', 'Unavailable'].forEach((choice) => {
          expect(screen.queryByText(choice)).not.toBeInTheDocument();
        });
      });

      it('prevents editing of priority case distribution dropdown', async () => {
        setup(props);

        // Try to open menu
        await selectEvent.openMenu(screen.getByLabelText('priorityCaseDistribution-1'));

        ['AMA cases only', 'Unavailable'].forEach((choice) => {
          expect(screen.queryByText(choice)).not.toBeInTheDocument();
        });
      });

      it('prevents editing of requested case distribution dropdown', async () => {
        setup(props);

        // Try to open menu
        await selectEvent.openMenu(screen.getByLabelText('requestedDistribution-1'));

        ['AMA cases only'].forEach((choice) => {
          expect(screen.queryByText(choice)).not.toBeInTheDocument();
        });
      });
    });

    describe('with edit permissions', () => {
      const onUpdate = jest.fn();
      const props = {
        ...judgeTeam,
        showDistributionToggles: true,
        current_user_can_toggle_priority_pushed_cases: true,
        onUpdate
      };

      it('renders correctly', () => {
        const { container } = setup(props);

        expect(container).toMatchSnapshot();
      });

      it('passes a11y testing', async () => {
        const { container } = setup(props);

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });

      describe('priority cases dropdown', () => {
        const labelText = 'priorityCaseDistribution-1';
        const dropdownOpts = priorityPushOpts.map((opt) => opt.label);
        const testOpts = [
          { label: priorityPushOpts[0].label, payload: { accepts_priority_pushed_cases: true, ama_only_push: false } },
          { label: priorityPushOpts[1].label, payload: { accepts_priority_pushed_cases: true, ama_only_push: true } },
          { label: priorityPushOpts[2].label, payload: { accepts_priority_pushed_cases: false, ama_only_push: false } },
        ];

        it('allows editing of priority case distribution dropdown', async () => {
          const { container } = setup(props);

          const control = container.getElementsByClassName(`dropdown-${labelText}`)[0];

          // Try to open menu
          await selectEvent.openMenu(screen.getByLabelText(labelText));

          dropdownOpts.slice(1).forEach((choice) => {
            expect(within(control).queryByText(choice)).toBeInTheDocument();
          });
        });

        it.each(testOpts)('correctly fires callback for $label', async ({ label, payload }) => {
          const { container } = setup(props);

          const control = container.getElementsByClassName(`dropdown-${labelText}`)[0];

          // Try to open menu
          await selectEvent.openMenu(within(control).getByLabelText(labelText));

          // Select "AMA cases only"
          await selectEvent.select(
            within(control).getByLabelText(labelText),
            label
          );

          expect(onUpdate).toHaveBeenLastCalledWith(judgeTeam.id, payload);
        });
      });

      describe('request cases dropdown', () => {
        const labelText = 'requestedDistribution-1';

        const testOpts = [
          { label: requestCasesOpts[0].label, payload: { ama_only_request: false } },
          { label: requestCasesOpts[1].label, payload: { ama_only_request: true } },
        ];

        it('allows editing of requested case distribution dropdown', async () => {
          setup(props);

          // Try to open menu
          await selectEvent.openMenu(screen.getByLabelText('requestedDistribution-1'));

          ['AMA cases only'].forEach((choice) => {
            expect(screen.queryByText(choice)).toBeInTheDocument();
          });
        });

        it.each(testOpts)('correctly fires callback for $label', async ({ label, payload }) => {
          const { container } = setup(props);

          const control = container.getElementsByClassName(`dropdown-${labelText}`)[0];

          // Try to open menu
          await selectEvent.openMenu(within(control).getByLabelText(labelText));

          // Select "AMA cases only"
          await selectEvent.select(
            within(control).getByLabelText(labelText),
            label
          );

          expect(onUpdate).toHaveBeenLastCalledWith(judgeTeam.id, payload);
        });
      });

    });
  });

  describe('with VSO', () => {
    const vso = createVso(1)[0];
    const props = { ...vso, isRepresentative: true };

    it('renders correctly', () => {
      const { container } = setup(props);

      expect(container).toMatchSnapshot();
    });

    it('passes a11y testing', async () => {
      const { container } = setup(props);

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  describe('status indicators', () => {
    const statuses = ['saved', 'loading', 'error'];

    describe.each(statuses)(' status: %s', (test) => {
      const status = { loading: false, saved: false, error: false, [test]: true };

      it('renders correctly', () => {
        const { container } = setup({ status });

        expect(container).toMatchSnapshot();
      });

      it('passes a11y testing', async () => {
        const { container } = setup({ status });

        const results = await axe(container);

        expect(results).toHaveNoViolations();
      });

      it('has `status` role', () => {
        setup({ status });

        expect(screen.getByRole('status')).toBeInTheDocument();
      });
    });
  });
});
