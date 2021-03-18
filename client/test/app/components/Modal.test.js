import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import Modal from 'app/components/Modal';
import Button from 'app/components/Button';

describe('Modal', () => {
  const title = 'Test Modal Title';
  const modalBodyContent = 'This is text content';
  let cancel, closeHandler, goBack;

  closeHandler = cancel = goBack = jest.fn();

  const defaultProps = {
    title,
    closeHandler,
    cancelButton: <Button onClick={cancel}> Cancel </Button>,
    confirmButton: <Button onClick={goBack}> Confirm </Button>,
  };

  const setupComponent = (props) => {
    return render(<Modal {...defaultProps} {...props}>
      <p>{modalBodyContent}</p>
    </Modal>);
  };

  it('renders correctly', () => {
    const { container } = setupComponent();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setupComponent();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders title', () => {
    setupComponent();

    expect(screen.getByText(defaultProps.title)).toBeInTheDocument();
  });

  it('renders body content', () => {
    setupComponent();

    expect(screen.getByText(modalBodyContent)).toBeInTheDocument();
  });

  it('renders divider if noDivider set to false', () => {
    const { container } = setupComponent();

    // Not recommended way of testing but element does not have text, role, or id
    expect(container.querySelector('.cf-modal-divider')).toBe(true);
  });

  it('does not render divider if noDivider set to true', () => {
    const { container } = setupComponent({ noDivider: true });

    // Not recommended way of testing but element does not have text, role, or id
    expect(container.querySelector('.cf-modal-divider')).toBe(true);
  });

  describe('buttons', () => {
    it('renders close button', async() => {
      const { container } = setupComponent();
      const closeButton = container.firstChild.firstChild.firstChild;

      await userEvent.click(closeButton);

      expect(closeButton).toBeInTheDocument();
      expect(defaultProps.closeHandler).toHaveBeenCalledTimes(1);
    });

    it('renders cancel and confirm buttons', async() => {
      setupComponent();
      const cancelButton = screen.getByText('Cancel');
      const confirmButton = screen.getByText('Confirm');

      expect(cancelButton).toBeInTheDocument();
      expect(confirmButton).toBeInTheDocument();

      await userEvent.click(cancelButton);
      expect(defaultProps.buttons[0].onClick).toHaveBeenCalledTimes(1);

      await userEvent.click(confirmButton);
      expect(defaultProps.buttons[1].onClick).toHaveBeenCalledTimes(1);
    });

    it('renders array of buttons', async() => {
      const props = {
        title,
        closeHandler,
        buttons: [
          {
            classNames: ['cf-modal-link', 'cf-btn-link'],
            name: 'Cancel',
            onClick: jest.fn(),
          },
          {
            classNames: ['usa-button'],
            name: 'Edit',
            onClick: jest.fn(),
          },
          {
            classNames: ['usa-button', 'usa-button-secondary'],
            name: 'Continue',
            onClick: jest.fn(),
          }
        ]
      };

      render(<Modal {...props} />);

      for (let button of props.buttons) {
        const buttonElement = screen.getByText(button.name);

        expect(buttonElement).toBeInTheDocument();

        await userEvent.click(buttonElement);
        expect(button.onClick).toHaveBeenCalledTimes(1);
      }
    });
  });
});
