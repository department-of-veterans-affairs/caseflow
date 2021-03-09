import React from 'react';
import { render, screen } from '@testing-library/react';
import Alert from 'app/components/Alert';
import { axe } from 'jest-axe';

describe('Alert', () => {
  const title = 'This is a title';
  const message = 'This';
  const types = ['error', 'info', 'success', 'warning'];

  describe.each(types)(' type: %s', (type) => {
    const props = { title, message, type };

    it(`renders correctly for ${type} alert`, () => {
      const component = render(<Alert {...props} />);

      expect(component).toMatchSnapshot();
    });

    it('passes a11y testing', async () => {
      const { container } = render(<Alert {...props} />);

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it(`shows ${type} banner`, () => {
      render(<Alert {...props} />);

      expect(screen.getByRole('alert')).toHaveClass(`usa-alert-${type}`);
    });

    it('shows message content', () => {
      render(<Alert {...props} />);

      expect(screen.getByText(props.message)).toBeTruthy();
    });

    it('scrolls to window top when scroll to top set to true by default', () => {
      render(<Alert {...props} />);
      expect(window.scrollTo).toHaveBeenCalledWith(0, 0);
    });
  });
});
