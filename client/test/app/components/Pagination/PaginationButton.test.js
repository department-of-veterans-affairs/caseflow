import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { axe } from 'jest-axe';

import PaginationButton from 'app/components/Pagination/PaginationButton';

describe('PaginationButton', () => {
  const handleChange = jest.fn();
  const defaults = {
    currentPage: 0,
    index: 0,
    handleChange,
  };
  const setup = (props = {}) =>
    render(<PaginationButton {...defaults} {...props} />);
  const currentPageClass = 'cf-current-page';

  describe('button for the current page', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    it('passes a11y', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    // The currentPageClass with _table.scss styling makes this a filled, primary, button
    it('has the current page class', () => {
      setup({ currentPage: 0 });
      expect(screen.getByRole('button')).toHaveClass(currentPageClass);
    });
  });

  describe('button for page other than current', () => {
    it('renders correctly', () => {
      const { container } = setup({ currentPage: 1 });

      expect(container).toMatchSnapshot();
    });

    it('passes a11y', async () => {
      const { container } = setup({ currentPage: 1 });

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    // The lack of class and _table.scss styling renders an unfilled button
    it('has no classes', () => {
      setup({ currentPage: 1 });
      expect(screen.getByRole('button')).not.toHaveClass(currentPageClass);
    });
  });

  it('calls handleChange when clicked', async () => {
    const component = setup({ currentPage: 1 });

    // Calls onChange handler
    await userEvent.click(component.getByRole('button'));

    expect(handleChange).toHaveBeenCalledTimes(1);
  });

});
