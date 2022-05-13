import React from 'react';
import { Button } from 'app/hearings/components/dailyDocket/DailyDocketRow';
import { render } from '@testing-library/react';
import { fireEvent } from '@testing-library/react';

describe('<Conference Link Button Renders Here />', () => {
  it('Prop works & contains the displayed text', () => {
    let clicked = false;
    const { getByText } = render(<Button connect={() => clicked = true} />);
    const conferenceLinkButton = getByText(/Connect/i);

    fireEvent.click(conferenceLinkButton);
    expect(clicked).toBe(true);
  });
});
