import React from 'react';
import { render } from '@testing-library/react';
import { PoaRefresh } from 'app/queue/components/PoaRefresh';

describe('PoaRefresh', () => {
  const powerOfAttorney = { poa_last_synced_at: '04/08/2021' };

  it('renders correctly', () => {
    const { container } = render(<PoaRefresh powerOfAttorney={powerOfAttorney} />);

    expect(container).toMatchSnapshot();
  });
});
