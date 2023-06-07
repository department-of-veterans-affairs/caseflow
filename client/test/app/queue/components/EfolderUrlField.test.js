import React from 'react';
import { render, screen } from '@testing-library/react';

import EfolderUrlField from 'app/queue/components/EfolderUrlField';

const renderComponent = (props) => render(<EfolderUrlField {...props} />);

describe('EfolderUrlField', () => {
  it('Renders correctly', () => {
    renderComponent({
      requestType: 'postponement'
    });

    const label = screen.getByText(
      'Insert Caseflow Reader document hyperlink to request a hearing postponement'
    );

    expect(label).toBeTruthy();
  });
});
