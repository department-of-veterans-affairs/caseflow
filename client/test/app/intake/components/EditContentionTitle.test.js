import React from 'react';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { EditContentionTitle } from 'app/intake/components/EditContentionTitle';
import COPY from '../../../../COPY';

const defaults = {
  issue: {
    date: '2020-01-15',
    editedDescription: 'Tinnitus',
    id: 1,
    index: 2,
    notes: '',
    text: 'Tinnitus',
  },
  issueIdx: 2,
};

describe('EditContentionTitle', () => {
  const setEditContentionText = jest.fn();

  jest.useFakeTimers('modern');

  afterEach(() => {
    jest.clearAllMocks();
  });

  const setup = (props) =>
    render(
      <EditContentionTitle
        setEditContentionText={setEditContentionText}
        {...defaults}
        {...props}
      />
    );

  const editMode = () =>
    userEvent.click(screen.getByText(COPY.INTAKE_EDIT_TITLE));

  it('renders correctly in default mode', () => {
    const { container } = setup();

    expect(screen.queryByText(COPY.INTAKE_EDIT_TITLE)).toBeTruthy();

    expect(container).toMatchSnapshot();
  });

  it('renders correctly in edit mode', () => {
    const { container } = setup();

    editMode();

    expect(screen.queryByText(COPY.INTAKE_EDIT_TITLE)).not.toBeTruthy();

    // Verify the label contents
    expect(
      screen.queryByLabelText(`${defaults.issueIdx + 1}. Contention title`)
    ).toBeTruthy();

    // Verify the value of the textarea
    expect(screen.getByRole('textbox')).toHaveTextContent(defaults.issue.text);

    // Verify the existing/prior value is also displayed below the textarea
    expect(screen.queryAllByText(defaults.issue.text).length).toEqual(2);

    // Verify buttons
    expect(screen.queryByRole('button', { name: /cancel/i })).toBeTruthy();
    expect(screen.queryByRole('button', { name: /submit/i })).toBeTruthy();

    expect(container).toMatchSnapshot();
  });

  it('shows issue notes if applicable', () => {
    const notes = 'Lorem ipsum dolor sit amet.';

    setup({ ...defaults, issue: { ...defaults.issue, notes } });

    expect(screen.queryByText(notes)).not.toBeTruthy();
    editMode();
    expect(screen.queryByText(`Notes: ${notes}`)).toBeTruthy();
  });

  it('should allow user to cancel editing', () => {
    setup();

    editMode();

    userEvent.click(screen.getByText('Cancel'));
    expect(screen.queryByText(/cancel/i)).not.toBeTruthy();
    expect(screen.queryByText(COPY.INTAKE_EDIT_TITLE)).toBeTruthy();
  });

  it('should prefer edited description if exists', () => {
    const editedDescription = 'foo';

    setup({ ...defaults, issue: { ...defaults.issue, editedDescription } });

    editMode();

    // Shouldn't display issue.text
    expect(screen.queryAllByText(defaults.issue.text).length).toEqual(0);

    // Should display issue.editedDescription
    expect(screen.queryAllByText(editedDescription).length).toEqual(2);
  });

  it('submits updated value to callback', () => {
    const newVal = 'foo bar';

    setup();

    editMode();

    userEvent.clear(screen.getByRole('textbox'));
    userEvent.type(screen.getByRole('textbox'), newVal);

    userEvent.click(screen.getByRole('button', { name: /submit/i }));

    expect(setEditContentionText).toHaveBeenCalledWith(
      defaults.issueIdx,
      'foo bar'
    );
  });

  it('shows both initial and updated values when editing again', () => {
    const newVal = 'foo bar';

    setup();

    editMode();

    userEvent.clear(screen.getByRole('textbox'));
    userEvent.type(screen.getByRole('textbox'), newVal);

    userEvent.click(screen.getByRole('button', { name: /submit/i }));

    editMode();

    // Verify the value of the textarea
    expect(screen.getByRole('textbox')).toHaveTextContent(newVal);

    // Verify we're displaying the original text under the textarea
    expect(screen.queryByText(defaults.issue.text)).toBeTruthy();
  });
});
