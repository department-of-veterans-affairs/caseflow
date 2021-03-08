import React from 'react';
import { render, screen } from '@testing-library/react';
import Alert from 'app/components/Alert';

describe('Alert', () => {
  const title = 'This is a title';

  describe('shows correct alert type', () => {

    it('shows info banner', () => {
      const props = {
        title,
        type: 'info'
      };

      render(<Alert {...props} />);

      expect(screen.getByRole('alert')).toHaveClass('usa-alert-info');
    });

    it('shows warning banner', () => {
      const props = {
        title,
        type: 'warning'
      };

      render(<Alert {...props} />);

      expect(screen.getByRole('alert')).toHaveClass('usa-alert-warning');
    });

    it('shows error banner', () => {
      const props = {
        title,
        type: 'error'
      };

      render(<Alert {...props} />);

      expect(screen.getByRole('alert')).toHaveClass('usa-alert-error');
    });

    it('shows success banner', () => {
      const props = {
        title,
        type: 'success'
      };

      render(<Alert {...props} />);

      expect(screen.getByRole('alert')).toHaveClass('usa-alert-success');
    });
  });

  describe('shows text content', () => {

    it('shows title in banner', () => {
      const props = {
        title,
        type: 'info'
      };

      render(<Alert {...props} />);

      expect(screen.getByText(title)).toBeTruthy();
    });

    it('shows message in banner', () => {
      const props = {
        title,
        type: 'info',
        message: 'Message content below title'
      };

      render(<Alert {...props} />);

      expect(screen.getByText(props.message)).toBeTruthy();
    });
  });

  describe('scroll to prop', () => {
    it('scrolls to window top', () => {
      const props = {
        title,
        type: 'info'
      };

      render(<Alert {...props} />);
      expect(window.scrollTo).toHaveBeenCalledWith(0, 0);
    });
  });
});
