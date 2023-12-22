import React from 'react';
import { fireEvent, render } from '@testing-library/react';
import NotificationResponseButton from '../../../app/queue/components/NotificationResponseButton';

describe('NotificationResponseButton', () => {
  const toggleResponseDetails = jest.fn();

  const setup = () => {
    return render(<NotificationResponseButton toggleResponseDetails={toggleResponseDetails} />);
  };

  it('renders a "+" by default', () => {
    const { container } = setup();

    expect(container.querySelector('.PlusIcon')).toBeTruthy();
  });

  it('render a "-" after clicked on', async () => {
    const { container } = setup();

    fireEvent.click(container.querySelector('.PlusIcon'));
    expect(container.querySelector('.MinusIcon')).toBeTruthy();
  });
});
