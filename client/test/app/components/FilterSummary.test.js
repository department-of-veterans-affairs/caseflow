import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import FilterSummary from 'app/components/FilterSummary';

describe('FilterSummary', () => {
  const clearFilteredByList = jest.fn();
  const defaults = {
    clearFilteredByList,
    filteredByList: {},
  };
  const setup = (props = {}) =>
    render(<FilterSummary {...defaults} {...props} />);

  describe('no selections', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    it('passes a11y', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  describe('one selection', () => {
    const filteredByList = {
      label: ['Review'],
    };

    it('renders correctly', () => {
      const { container } = setup({ filteredByList });

      expect(container).toMatchSnapshot();

      expect(screen.getByText('Filtering by:')).toBeInTheDocument();
      expect(screen.getByText('Tasks (1)')).toBeInTheDocument();
    });

    it('passes a11y', async () => {
      const { container } = setup({ filteredByList });

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  describe('multiple selections', () => {
    const filteredByList = {
      'appeal.caseType': ['Original', 'Post Remand'],
      label: ['Review'],
    };

    it('renders correctly', () => {
      const { container } = setup({ filteredByList });

      expect(container).toMatchSnapshot();

      expect(screen.getByText('Filtering by:')).toBeInTheDocument();
      expect(screen.getByText('Case Type (2)')).toBeInTheDocument();
      expect(screen.getByText('Tasks (1)')).toBeInTheDocument();
    });

    it('passes a11y', async () => {
      const { container } = setup({ filteredByList });

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  describe('callbacks', () => {
    const filteredByList = {
      label: ['Review'],
    };

    it('calls clearFilteredByList when clicked', async () => {
      setup({ filteredByList });

      expect(clearFilteredByList).not.toHaveBeenCalled();

      await userEvent.click(
        screen.getByRole('button', { name: /clear all filters/i })
      );

      expect(clearFilteredByList).toHaveBeenCalled();
    });
  });
});
