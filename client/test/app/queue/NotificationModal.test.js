import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import NotificationModal from '../../../app/queue/components/NotificationModal';

describe('NotificationModal', () => {
  const eventType = 'Test Notification Modal Title';
  const notificationContent = '"This is the content"';
  const closeNotificationModal = jest.fn();

  const defaultProps = {
    eventType,
    notificationContent,
    closeNotificationModal
  };

  const setupComponent = () => {
    return render(<NotificationModal {...defaultProps} />
    );
  };

  it('passes a11y testing', async () => {
    const { container } = setupComponent();
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders title', () => {
    setupComponent();
    expect(screen.getByText(defaultProps.eventType)).toBeInTheDocument();
  });

  it('renders body content', async () => {
    setupComponent();

    expect(screen.getByTestId('body-content')).toBeInTheDocument();
  });

  it('renders divider', () => {
    const { container } = setupComponent();

    expect(container.querySelector('.cf-modal-divider')).toBeTruthy();
  });

  describe('buttons', () => {
    it('renders close button', async() => {
      setupComponent();
      const confirmButton = screen.getByText('close');

      await userEvent.click(confirmButton);

      expect(confirmButton).toBeInTheDocument();
      expect(defaultProps.closeNotificationModal).toHaveBeenCalledTimes(1);
    });
  });
});
