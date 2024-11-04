import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { EditNodDateModal } from 'app/queue/components/EditNodDateModal';

describe('EditNodDateModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const defaultNodDate = '2020-10-31';
  const appealId = 'tb78ti7in77n';
  const showTimelinessError = false;
  const defaults = {
    appealId,
    onSubmit,
    onCancel,
    nodDate: defaultNodDate,
    showTimelinessError
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(<EditNodDateModal {...defaults} />);

    expect(container).toMatchSnapshot();
  });

  it('should fire cancel event', async () => {
    render(<EditNodDateModal {...defaults} />);

    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));

    expect(onCancel).toHaveBeenCalled();
  });
});
