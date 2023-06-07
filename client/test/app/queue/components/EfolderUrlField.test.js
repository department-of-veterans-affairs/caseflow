import React from 'react';
import { render, screen } from '@testing-library/react';

import EfolderUrlField from 'app/queue/components/EfolderUrlField';

const renderComponent = () => render(<EfolderUrlField />);

describe('EfolderUrlField', () => {
  it('Renders correctly', () => {
    renderComponent();

    const header = screen.getByText('Test');

    expect(header).toBeTruthy();
  });
});
