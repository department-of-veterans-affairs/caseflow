import React from 'react';
import { conferenceLink } from 'app/hearings/components/dailyDocket/DailyDocketRow';
import { render, fireEvent } from '@testing-library/react';

describe('<Conference Link Button Renders Here />', () => {

  it('Prop works & contains the displayed text', () => {
    let clicked = false;
    const { getByText } = render(<conferenceLink connect={() => clicked = true} />);

    getByText(/Connect/i);

    fireEvent.click(conferenceLink);
    expect(clicked).toBe(false);
  });
});
