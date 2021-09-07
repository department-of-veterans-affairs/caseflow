import React from 'react';
import { render, screen } from '@testing-library/react';

import { axe } from 'jest-axe';

import { OrgRow } from 'app/queue/teamManagement/OrgRow';
import { createJudgeTeam, createVso } from 'test/data/teamManagement';

describe('OrgRow', () => {
  const defaults = {};

  const setup = (props) =>
    render(<OrgRow {...defaults} {...props} />);

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
    const props = { judgeTeam };

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

  describe('with VSO', () => {
    const vso = createVso(1)[0];
    const props = { vso, isRepresentative: true };

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
