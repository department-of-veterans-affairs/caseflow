import React from 'react';
import { render, screen } from '@testing-library/react';
import Alert from 'app/components/Alert';
import { axe } from 'jest-axe';

describe('Alert', () => {
  const title = 'This is a title';
  const message = 'This is a message';
  const types = ['error', 'info', 'success', 'warning'];
  const scrollToSpy = jest.fn();

  global.window.scrollTo = scrollToSpy;

  beforeEach(() => {
    scrollToSpy.mockClear();
  });

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

    it('shows without message content', () => {
      const modifiedProps = { ...props };

      delete modifiedProps.message;
      render(<Alert {...modifiedProps} />);

      expect(screen.queryByText(props.message)).not.toBeInTheDocument();
    });

    it('scrolls to window top when scrollOnAlert set to true', () => {
      render(<Alert {...props} />);
      expect(window.scrollTo).toHaveBeenCalledWith(0, 0);
    });

    it('does not scroll to window top when scrollOnAlert set to false', () => {
      const modifiedProps = { ...props };

      modifiedProps.scrollOnAlert = false;
      render(<Alert {...modifiedProps} />);
      expect(window.scrollTo).toHaveBeenCalledTimes(0);
    });
  });
});
