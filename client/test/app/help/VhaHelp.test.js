import React from 'react';
import { render } from '@testing-library/react';
import VhaHelp from '../../../app/help/components/VhaHelp';

describe('VhaHelp', () => {
  test('renders the help page', () => {
    const { container } = render(<VhaHelp />);

    expect(container.innerHTML).toMatchSnapshot();
  });
});
