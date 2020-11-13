import React from 'react';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import { axe } from 'jest-axe';

import { EditClaimLabelModal } from 'app/intakeEdit/components/EditClaimLabelModal';

describe('EditClaimLabelModal', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const defaults = { onCancel, onSubmit, existingEpCode: '040HDENR' };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(<EditClaimLabelModal {...defaults} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(<EditClaimLabelModal {...defaults} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should fire cancel event', async () => {
    render(<EditClaimLabelModal {...defaults} />);

    await userEvent.click(screen.getByText('Cancel'));
    expect(onCancel).toHaveBeenCalled();
  });

  it('defaults to the current claim label', async () => {
    render(<EditClaimLabelModal {...defaults} />);

    // Preselected, the code should show on screen
    expect(screen.getByText(defaults.existingEpCode)).toBeInTheDocument();
  });

  describe('correctly filters by EP code family', () => {
    it('displays only codes from 040 family', async () => {
      render(<EditClaimLabelModal {...defaults} />);

      const input = screen.getByLabelText(/select the correct ep claim label/i);

      await userEvent.click(input);
      expect(screen.queryAllByText(/040[a-zA-Z]/).length).toBeTruthy();
      expect(screen.queryAllByText(/030[a-zA-Z]/).length).not.toBeTruthy();
      expect(screen.queryAllByText(/930[a-zA-Z]/).length).not.toBeTruthy();
    });

    it('displays only codes from 030 family', async () => {
      render(<EditClaimLabelModal {...defaults} existingEpCode="030HLRFID" />);

      const input = screen.getByLabelText(/select the correct ep claim label/i);

      await userEvent.click(input);
      expect(screen.queryAllByText(/030[a-zA-Z]/).length).toBeTruthy();
      expect(screen.queryAllByText(/040[a-zA-Z]/).length).not.toBeTruthy();
      expect(screen.queryAllByText(/930[a-zA-Z]/).length).not.toBeTruthy();
    });

    it('displays only codes from 930 family', async () => {
      render(
        <EditClaimLabelModal {...defaults} existingEpCode="930AHCNRLPMC" />
      );

      const input = screen.getByLabelText(/select the correct ep claim label/i);

      await userEvent.click(input);
      expect(screen.queryAllByText(/030[a-zA-Z]/).length).not.toBeTruthy();
      expect(screen.queryAllByText(/040[a-zA-Z]/).length).not.toBeTruthy();
      expect(screen.queryAllByText(/930[a-zA-Z]/).length).toBeTruthy();
    });
  });

  //   it.skip('should display notes only if "claimant not listed" is selected', () => {
  //     render(
  //       <AddClaimantModal
  //         onSearch={performQuery}
  //         onCancel={onCancel}
  //         onSubmit={onSubmit}
  //       />
  //     );

  //     expect(screen.queryByLabelText(/notes.*/i)).not.toBeTruthy();

  //     userEvent.click(screen.getByLabelText(/claimant not listed/i));

  //     expect(screen.queryByLabelText(/notes.*/i)).toBeTruthy();
  //   });

  //   it('should clear dropdown', async () => {
  //     render(
  //       <AddClaimantModal
  //         onSearch={performQuery}
  //         onCancel={onCancel}
  //         onSubmit={onSubmit}
  //       />
  //     );

  //     const input = screen.getByLabelText(/claimant's name/i);

  //     // Enter sufficient search, and wait for select options to show
  //     await userEvent.type(input, data[0].name.substr(0, 4));
  //     jest.advanceTimersByTime(DEBOUNCE);
  //     await waitFor(() => screen.getByText(data[0].name));

  //     // Select claimant
  //     await userEvent.click(screen.getByText(data[0].name));

  //     // Claimant name is shown
  //     expect(screen.queryByText(data[0].name)).toBeTruthy();

  //     // Use the `react-select` clear functionality
  //     await selectEvent.clearFirst(input);

  //     // Claimant name should no longer be shown
  //     expect(screen.queryByText(data[0].name)).not.toBeTruthy();
  //   });

  //   describe.skip('changes based on "claimant not listed" selection', () => {
  //     it('should display notes only if "claimant not listed" is selected', () => {
  //       render(
  //         <AddClaimantModal
  //           onSearch={performQuery}
  //           onCancel={onCancel}
  //           onSubmit={onSubmit}
  //         />
  //       );

  //       // Notes field should be hidden by default
  //       expect(screen.queryByLabelText(/notes.*/i)).not.toBeTruthy();

  //       userEvent.click(screen.getByLabelText(/claimant not listed/i));

  //       // Notes field should now be shown
  //       expect(screen.queryByLabelText(/notes.*/i)).toBeTruthy();
  //     });

  //     it('should not change relationship field if "claimant not listed" is selected', async () => {
  //       const { container } = render(
  //         <AddClaimantModal
  //           onSearch={performQuery}
  //           onCancel={onCancel}
  //           onSubmit={onSubmit}
  //         />
  //       );

  //       const { queryByText } = within(
  //         container.querySelector(
  //           '.dropdown-relationship .cf-select__single-value'
  //         )
  //       );

  //       // Relationship should be set to "attorney"
  //       expect(queryByText(/attorney/i)).toBeTruthy();

  //       userEvent.click(screen.getByLabelText(/claimant not listed/i));

  //       expect(queryByText(/attorney/i)).toBeTruthy();
  //     });
  //   });

  //   describe('it prevents submit unless valid', () => {
  //     test('with found claimant', async () => {
  //       render(
  //         <AddClaimantModal
  //           onSearch={performQuery}
  //           onCancel={onCancel}
  //           onSubmit={onSubmit}
  //         />
  //       );

  //       const input = screen.getByLabelText(/claimant's name/i);
  //       const submit = screen.getByRole('button', { name: /add this claimant/i });

  //       userEvent.click(submit);
  //       expect(onSubmit).not.toHaveBeenCalled();

  //       // Enter sufficient search, and wait for select options to show
  //       await userEvent.type(input, data[0].name.substr(0, 4));
  //       jest.advanceTimersByTime(DEBOUNCE);
  //       await waitFor(() => screen.getByText(data[0].name));

  //       // Select claimant
  //       await userEvent.click(screen.getByText(data[0].name));

  //       // Click submit
  //       userEvent.click(submit);
  //       expect(onSubmit).toHaveBeenCalledWith(
  //         expect.objectContaining({
  //           name: data[0].name,
  //           participantId: data[0].participant_id,
  //           claimantType: 'attorney',
  //           claimantNotes: '',
  //         })
  //       );
  //     });

  //     test.skip('with unlisted claimant', async () => {
  //       render(
  //         <AddClaimantModal
  //           onSearch={performQuery}
  //           onCancel={onCancel}
  //           onSubmit={onSubmit}
  //         />
  //       );

  //       const submit = screen.getByRole('button', { name: /add this claimant/i });

  //       userEvent.click(submit);
  //       expect(onSubmit).not.toHaveBeenCalled();

  //       userEvent.click(screen.getByLabelText(/claimant not listed/i));

  //       // Should still be invalid, due to notes field
  //       userEvent.click(submit);
  //       expect(onSubmit).not.toHaveBeenCalled();

  //       // Fill in notes
  //       userEvent.type(screen.getByLabelText(/notes.*/i), 'foo');

  //       // Click submit
  //       userEvent.click(submit);
  //       expect(onSubmit).toHaveBeenCalledWith(
  //         expect.objectContaining({
  //           claimantType: 'other',
  //           claimantNotes: 'foo',
  //         })
  //       );
  //     });
  //   });

  //   describe('claimant search', () => {
  //     jest.useFakeTimers('modern');

  //     let func;

  //     beforeEach(() => {
  //       func = jest.fn(performQuery);
  //     });

  //     test('enforces minimum characters', async () => {
  //       render(
  //         <AddClaimantModal
  //           onSearch={func}
  //           onCancel={onCancel}
  //           onSubmit={onSubmit}
  //         />
  //       );
  //       const input = screen.getByLabelText(/claimant's name/i);

  //       // enter insufficient characters
  //       await userEvent.type(input, data[0].name.substr(0, 2));
  //       jest.advanceTimersByTime(DEBOUNCE);
  //       expect(func).not.toHaveBeenCalled();

  //       await userEvent.type(input, data[0].name.substr(0, 1));
  //       jest.advanceTimersByTime(DEBOUNCE);
  //       expect(func).toHaveBeenCalled();
  //     });

  //     test('just once', async () => {
  //       render(
  //         <AddClaimantModal
  //           onSearch={func}
  //           onCancel={onCancel}
  //           onSubmit={onSubmit}
  //         />
  //       );
  //       const input = screen.getByLabelText(/claimant's name/i);

  //       // enter insufficient characters
  //       await userEvent.type(input, 'A');
  //       jest.advanceTimersByTime(DEBOUNCE);
  //       expect(func).not.toHaveBeenCalled();

  //       await userEvent.type(input, 'BC');
  //       expect(func).not.toHaveBeenCalled();
  //       jest.advanceTimersByTime(DEBOUNCE);
  //       expect(func).toHaveBeenCalled();
  //       expect(func).toBeCalledTimes(1);
  //       await userEvent.type(input, 'DEF');
  //       expect(func).toBeCalledTimes(1);
  //       await userEvent.type(input, 'GHI');
  //       expect(func).toBeCalledTimes(1);
  //       jest.advanceTimersByTime(DEBOUNCE);
  //       expect(func).toBeCalledTimes(2);

  //       // Ensure that we don't call if no additional input
  //       jest.advanceTimersByTime(DEBOUNCE);
  //       expect(func).toBeCalledTimes(2);
  //     });
  //   });
});
