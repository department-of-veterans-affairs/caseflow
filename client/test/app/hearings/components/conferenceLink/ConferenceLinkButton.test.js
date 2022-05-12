import React from 'react';
import { Button } from 'app/hearings/components/dailyDocket/DailyDocketRow';

describe('Test Button component', () => {
  it('Test click event', () => {
    const mockCallBack = jest.fn();
    const button = ((<Button
      classNames={['usa-button-secondary']}
      type="button"
      name="conferenceOnClick"
      onClick={mockCallBack} > Connect to Recording System</Button>));

    button.simulate('click');
    expect(mockCallBack.mock.calls).toEqual(true);
  });
});
