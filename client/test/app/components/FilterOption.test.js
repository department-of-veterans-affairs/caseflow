import React from 'react';
import { render, screen } from '@testing-library/react';
import FilterOption from 'app/components/FilterOption';
import { axe } from 'jest-axe';

describe('FilterOption', () => {
  const props = {
    options: [
      { value: 'option1', displayText: 'Option 1', checked: true },
      { value: 'option2', displayText: 'Option 2', checked: false },
      { value: 'option3', displayText: 'Option 3', checked: false }
    ],
    setSelectedValue: () => {},
  };

  it('passes a11y testing', async () => {
    const { container } = render(<FilterOption {...props} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('shows all options', async () => {
    await render(<FilterOption {...props} />);

    const options = props.options;

    options.forEach((opt) => {
      expect(screen.queryByText(opt.displayText)).not.toBeNull();
    });
  });
});
