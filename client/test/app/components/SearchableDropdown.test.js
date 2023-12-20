import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import faker from 'faker';

import { axe } from 'jest-axe';

import { SearchableDropdown } from 'app/components/SearchableDropdown';

const options = [
  { label: 'Option 1', value: 'value1' },
  { label: 'Option 2', value: 'value2' },
  { label: 'Option 3', value: 'value3' },
  { label: 'Option 4', value: 'value4' },
];

describe('SearchableDropdown', () => {
  it('renders correctly', async () => {
    const { container } = await render(
      <SearchableDropdown name="menuTest" options={options} />
    );

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = await render(
      <SearchableDropdown name="menuTest" options={options} />
    );

    const results1 = await axe(container);

    expect(results1).toHaveNoViolations();

    // Try with menu open
    await selectEvent.openMenu(screen.getByLabelText('menuTest'));

    const results2 = await axe(container);

    expect(results2).toHaveNoViolations();
  });

  it('shows all options in menu when opened', async () => {
    await render(<SearchableDropdown name="menuTest" options={options} />);

    options.forEach((opt) => {
      expect(screen.queryByText(opt.label)).toBeNull();
    });

    await selectEvent.openMenu(screen.getByLabelText('menuTest'));
    options.forEach((opt) => {
      expect(screen.queryByText(opt.label)).not.toBeNull();
    });
  });

  it('correctly selects single option', async () => {
    const mockOnChange = jest.fn();

    await render(
      <SearchableDropdown
        name="menuTest"
        options={options}
        onChange={mockOnChange}
      />
    );

    await selectEvent.select(
      screen.getByLabelText('menuTest'),
      options[2].label
    );
    expect(mockOnChange).toHaveBeenLastCalledWith(options[2], null);
  });

  it('allows setting default value', async () => {
    const mockOnChange = jest.fn();

    await render(
      <SearchableDropdown
        name="menuTest"
        options={options}
        value={options[1]}
        onChange={mockOnChange}
      />
    );

    expect(screen.queryByText(options[1].label)).not.toBeNull();

    // Setting default doesn't count as changing, so callback should not fire
    expect(mockOnChange).toHaveBeenCalledTimes(0);
  });

  it('honors `readOnly` prop', async () => {
    const mockOnChange = jest.fn();

    await render(
      <SearchableDropdown
        name="menuTest"
        options={options}
        onChange={mockOnChange}
        readOnly
      />
    );

    // Try to open menu
    await selectEvent.openMenu(screen.getByLabelText('menuTest'));

    // Menu options should not be visible
    options.forEach((opt) => {
      expect(screen.queryByText(opt.label)).toBeNull();
    });

    // Callback should not have fired
    expect(mockOnChange).toHaveBeenCalledTimes(0);
  });

  it('supports clearing on selection', async () => {
    const mockOnChange = jest.fn();

    await render(
      <SearchableDropdown
        name="menuTest"
        options={options}
        onChange={mockOnChange}
        clearOnSelect
      />
    );

    await selectEvent.select(
      screen.getByLabelText('menuTest'),
      options[2].label
    );

    // Make sure option was selected
    expect(mockOnChange).toHaveBeenLastCalledWith(options[2], null);

    // But control should now have been cleared
    expect(screen.queryByText(options[2].label)).toBeNull();
  });

  it('supports multiple selection', async () => {
    const mockOnChange = jest.fn();

    await render(
      <SearchableDropdown
        name="menuTest"
        options={options}
        onChange={mockOnChange}
        multi
      />
    );

    await selectEvent.select(screen.getByLabelText('menuTest'), [
      options[0].label,
      options[2].label,
    ]);

    // Make sure option was selected
    expect(mockOnChange).toHaveBeenLastCalledWith(
      [options[0], options[2]],
      null
    );

    // We should now see the two selected options
    expect(screen.queryByText(options[0].label)).not.toBeNull();
    expect(screen.queryByText(options[2].label)).not.toBeNull();

    // ...but not the others
    expect(screen.queryByText(options[1].label)).toBeNull();
    expect(screen.queryByText(options[3].label)).toBeNull();
  });
});

describe('creatable', () => {
  it('supports adding a custom option', async () => {
    const mockOnChange = jest.fn();

    await render(
      <SearchableDropdown
        name="menuTest"
        options={options}
        onChange={mockOnChange}
        creatable
      />
    );

    await selectEvent.create(screen.getByLabelText('menuTest'), 'foo', {
      createOptionText: /^Create a tag for/,
    });

    // Make sure option was selected
    expect(mockOnChange).toHaveBeenLastCalledWith(
      expect.objectContaining({
        label: 'foo',
        value: 'foo',
      }),
      null
    );

    // But control should now have been cleared
    expect(screen.queryByText('foo')).not.toBeNull();
  });
});

describe('async', () => {
  const wait = (delay) =>
    new Promise((resolve) => setTimeout(() => resolve(), delay));

  const data = Array.from({ length: 250 }, () => ({
    label: faker.name.findName(),
    value: faker.random.number(),
  }));

  // Simple string search for mocking
  const fetchFn = async (search = '') => {
    const regex = RegExp(search, 'i');

    return data.filter((item) => regex.test(item.label));
  };

  const asyncFn = async (search = '') => {
    // Mock a delay for fetch
    await wait(750);

    return await fetchFn(search);
  };

  it('passes search to async fn', async () => {
    const mockOnChange = jest.fn();
    const mockSearch = jest.fn();

    await render(
      <SearchableDropdown
        name="menuTest"
        async={mockSearch}
        onChange={mockOnChange}
      />
    );

    await userEvent.click(screen.getByText('Select...'));
    await userEvent.type(screen.getByRole('combobox'), data[0].label);

    expect(mockSearch).toHaveBeenLastCalledWith(
      data[0].label,
      expect.any(Function)
    );
  });

  it('allows selection of async option', async () => {
    const mockOnChange = jest.fn();

    await render(
      <SearchableDropdown
        name="menuTest"
        async={asyncFn}
        onChange={mockOnChange}
      />
    );

    await userEvent.click(screen.getByText('Select...'));
    await userEvent.type(
      screen.getByRole('combobox'),
      data[0].label.slice(0, data[0].label.length - 2)
    );

    await selectEvent.select(screen.getByLabelText('menuTest'), data[0].label);

    expect(mockOnChange).toHaveBeenLastCalledWith(data[0], null);
  });
});
