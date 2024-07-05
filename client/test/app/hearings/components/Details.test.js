import React from 'react';
import { screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Wrapper, customRender } from '../../../helpers/testHelpers';
import { detailsStore } from 'test/data/stores/hearingsStore';
import {
  anyUser,
  legacyHearing,
  amaHearing,
  defaultHearing,
  virtualHearing,
  amaWebexHearing,
  legacyWebexHearing
} from 'test/data';
import Details from 'app/hearings/components/Details';

// Define the function spies
const saveHearingSpy = jest.fn();
const setHearingSpy = jest.fn();
const goBackSpy = jest.fn();
const onReceiveAlertsSpy = jest.fn();
const onReceiveTransitioningAlertSpy = jest.fn();
const transitionAlertSpy = jest.fn();
const mockSubmit = jest.fn(() => Promise.resolve());

const convertRegex = (str) => {
  return new RegExp(str, 'i');
}

const convertRegex = (str) => {
  return new RegExp(str, 'i');
}

const convertRegex = (str) => {
  return new RegExp(str, 'i');
}

const convertRegex = (str) => {
  return new RegExp(str, 'i');
}

describe('Details', () => {
  test('Matches snapshot with default props', () => {
    const {asFragment} = customRender(
      <Details
        hearing={defaultHearing}
        saveHearing={saveHearingSpy}
        setHearing={setHearingSpy}
        goBack={goBackSpy}
        onReceiveAlerts={onReceiveAlertsSpy}
        onReceiveTransitioningAlert={onReceiveTransitioningAlertSpy}
        transitionAlert={transitionAlertSpy}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          store: detailsStore,
          user: anyUser,
          hearing: defaultHearing
        },
      }
    );

    const veteranName = `${defaultHearing.veteranFirstName} ${defaultHearing.veteranLastName}`;
    // Assertions
    expect(screen.getByText(convertRegex(veteranName))).toBeInTheDocument();
    expect(screen.getByRole('heading', {name: convertRegex(veteranName)})).toBeInTheDocument();
    expect(screen.getAllByText(convertRegex("Hearing Details")).length).toBeGreaterThan(0);
    expect(screen.getAllByRole('heading', {name: convertRegex("Hearing Details")}).length).toBeGreaterThan(0);

    // Ensure that the virtualHearing form is not displayed by default
    expect(screen.queryByRole('heading', {name: "Virtual Hearing Links"})).toBeNull();

    // Ensure the transcription section is displayed by default for ama hearings
    expect(screen.getByRole('heading', {name: "Transcription Details"})).toBeInTheDocument();
    expect(screen.getByRole('heading', {name: "Transcription Problem"})).toBeInTheDocument();
    expect(screen.getByRole('heading', {name: "Transcription Request"})).toBeInTheDocument();

    // Ensure the save and cancel buttons are present
    expect(screen.getByRole('button', {name: "Cancel"})).toBeInTheDocument();
    expect(screen.getByRole('button', {name: "Save"})).toBeInTheDocument();

    // expect(details).toMatchSnapshot();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays HearingConversion when converting from central', () => {
    const {asFragment} = customRender(
      <Details
        hearing={amaHearing}
        saveHearing={saveHearingSpy}
        setHearing={setHearingSpy}
        goBack={goBackSpy}
        onReceiveAlerts={onReceiveAlertsSpy}
        onReceiveTransitioningAlert={onReceiveTransitioningAlertSpy}
        transitionAlert={transitionAlertSpy}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          store: detailsStore,
          user: anyUser,
          hearing: amaHearing
        },
      }
    );

    const dropdown = screen.getByRole('combobox', {name: "Hearing Type"});

    expect(screen.getByRole('heading', {name: "Email Notifications"})).toBeInTheDocument();
    expect(screen.queryByRole('heading', {name: "Convert to Central Hearing"})).not.toBeInTheDocument()

    // Change the value of the hearing type
    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });
    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });
    fireEvent.keyDown(dropdown, { key: 'Enter' });

    // Ensure the modal is displayed
    expect(screen.queryByRole('heading', {name: "Email Notifications"})).not.toBeInTheDocument();
    expect(screen.getByRole('heading', {name: "Convert to Central Hearing"})).toBeInTheDocument();
    expect(screen.queryByLabelText("POA/Representative Hearing Time")).toBeNull();
    expect(screen.queryByLabelText("POA/Representative Email")).toBeNull();
    expect(screen.queryByLabelText("Veteran Hearing Time")).toBeNull();
    expect(screen.queryByLabelText("Appellant Hearing Time")).toBeNull();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays HearingConversion when converting from video', () => {
    const {asFragment} = customRender(
      <Details
        hearing={defaultHearing}
        saveHearing={saveHearingSpy}
        setHearing={setHearingSpy}
        goBack={goBackSpy}
        onReceiveAlerts={onReceiveAlertsSpy}
        onReceiveTransitioningAlert={onReceiveTransitioningAlertSpy}
        transitionAlert={transitionAlertSpy}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          store: detailsStore,
          user: anyUser,
          hearing: defaultHearing
        },
      }
    );

    const dropdown = screen.getByRole('combobox', {name: "Hearing Type"});

    expect(screen.getByRole('heading', {name: "Email Notifications"})).toBeInTheDocument();
    expect(screen.queryByRole('heading', {name: "Convert to Virtual Hearing"})).not.toBeInTheDocument()

    // Change the value of the hearing type
    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });
    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });
    fireEvent.keyDown(dropdown, { key: 'Enter' });

    // Ensure the modal is displayed
    expect(screen.queryByRole('heading', {name: "Email Notifications"})).not.toBeInTheDocument();
    expect(screen.getByRole('heading', {name: "Convert to Virtual Hearing"})).toBeInTheDocument()
    expect(screen.queryByLabelText("POA/Representative Hearing Time")).toBeNull();
    expect(screen.queryByLabelText("POA/Representative Email")).toBeNull();
    expect(screen.queryByLabelText("Veteran Hearing Time")).toBeNull();
    expect(screen.queryByLabelText("Appellant Hearing Time")).toBeNull();

    // expect(details).toMatchSnapshot();
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays HearingConversion when converting from virtual', () => {
    const {asFragment} = customRender(
      <Details
        hearing={virtualHearing}
        saveHearing={saveHearingSpy}
        setHearing={setHearingSpy}
        goBack={goBackSpy}
        onReceiveAlerts={onReceiveAlertsSpy}
        onReceiveTransitioningAlert={onReceiveTransitioningAlertSpy}
        transitionAlert={transitionAlertSpy}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          store: detailsStore,
          user: anyUser,
          hearing: defaultHearing
        },
      }
    );

    const dropdown = screen.getByRole('combobox', {name: "Hearing Type"});

    expect(screen.getByRole('heading', {name: "Email Notifications"})).toBeInTheDocument();
    expect(screen.queryByRole('heading', {name: "Convert to Virtual Hearing"})).not.toBeInTheDocument()

    // Change the value of the hearing type
    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });
    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });
    fireEvent.keyDown(dropdown, { key: 'Enter' });

    expect(screen.queryByRole('heading', {name: "Email Notifications"})).not.toBeInTheDocument();
    expect(screen.getByRole('heading', {name: "Convert to Virtual Hearing"})).toBeInTheDocument()

    expect(asFragment()).toMatchSnapshot();
  });

  test('Does not display EmailConfirmationModal when updating transcription details with AMA virtual hearing', async () => {
    const {container, asFragment} = customRender(
      <Details
        hearing={amaHearing}
        saveHearing={saveHearingSpy}
        setHearing={setHearingSpy}
        goBack={goBackSpy}
        onReceiveAlerts={onReceiveAlertsSpy}
        onReceiveTransitioningAlert={onReceiveTransitioningAlertSpy}
        transitionAlert={transitionAlertSpy}
        submit={mockSubmit}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          store: detailsStore,
          user: anyUser,
          hearing: amaHearing
        },
      }
    );

    // Update the transcription sent date field
    let dateSelector = container.querySelector('#copySentDate');
    fireEvent.change(dateSelector, { target: { value: '2020-07-25' } });

    // Verify the date change
    dateSelector = container.querySelector('#copySentDate');
    expect(dateSelector.value).toBe('2020-07-25');

    // Click the save button
    const saveButton = screen.getByRole('button', { name: /Save/i });
    userEvent.click(saveButton);

    // Wait for and check the loading state of saving the hearing
    await waitFor(() => {
      const loadingButtonDecision = screen.getByRole('button', { name: /Loading.../i });
      expect(loadingButtonDecision).toBeInTheDocument();
      expect(screen.getByRole('button', { name: 'Loading...' })).toBeInTheDocument();
      expect(loadingButtonDecision).toBeDisabled();
    });

    dateSelector = container.querySelector('#copySentDate');
    expect(dateSelector.value).toBe('2020-07-25');

    // Ensure EmailConfirmationModal is not displayed
    expect(screen.queryByLabelText("POA/Representative Hearing Time")).toBeNull();
    expect(screen.queryByLabelText("POA/Representative Email")).toBeNull();
    expect(screen.queryByLabelText("Veteran Hearing Time")).toBeNull();
    expect(screen.queryByLabelText("Appellant Hearing Time")).toBeNull();

    expect(asFragment()).toMatchSnapshot();
  });

  describe('TranscriptiomFormSection', () => {
    describe('pexip hearing', () => {
      test('Displays transcription section but not transcription files table for AMA hearings', () => {
        const {container} = customRender(
          <Details
            hearing={amaHearing}
            saveHearing={saveHearingSpy}
            setHearing={setHearingSpy}
            goBack={goBackSpy}
            onReceiveAlerts={onReceiveAlertsSpy}
            onReceiveTransitioningAlert={onReceiveTransitioningAlertSpy}
            transitionAlert={transitionAlertSpy}
          />,
          {
            wrapper: Wrapper,
            wrapperProps: {
              store: detailsStore,
              user: anyUser,
              hearing: amaHearing
            },
          }
        );

        expect(screen.getByRole('heading', {name: "Transcription Details"})).toBeInTheDocument();
        expect(screen.getByTestId('transcription-details-inputs')).toBeInTheDocument();
        expect(screen.getByTestId('transcription-details-date-inputs')).toBeInTheDocument();
        expect(screen.getByTestId('transcription-problem-inputs')).toBeInTheDocument();
        expect(screen.getByTestId('transcription-request-inputs')).toBeInTheDocument();
        expect(container.querySelector('.transcription-files-table')).toBeNull();
      });

      test('Does not display transcription section for legacy hearings', () => {
        const {asFragment, container} = customRender(
          <Details
            hearing={legacyHearing}
            saveHearing={saveHearingSpy}
            setHearing={setHearingSpy}
            goBack={goBackSpy}
            onReceiveAlerts={onReceiveAlertsSpy}
            onReceiveTransitioningAlert={onReceiveTransitioningAlertSpy}
            transitionAlert={transitionAlertSpy}
          />,
          {
            wrapper: Wrapper,
            wrapperProps: {
              store: detailsStore,
              user: anyUser,
              hearing: legacyHearing
            },
          }
        );

        // Assertions
        expect(screen.getByTestId('details-header')).toBeInTheDocument();
        expect(screen.getByRole('heading', {name: "Hearing Details"})).toBeInTheDocument();


        // Ensure that the virtualHearing form is not displayed by default
        expect(screen.queryByRole('heading', {name: "Virtual Hearing Links"})).toBeNull();

        // VirtualHearingFields will always show for any virtual or non virtual hearing
        // as we move forward with Webex integration
        expect(screen.getByText(convertRegex("Pexip Hearing"))).toBeInTheDocument();

        // Ensure the transcription form is not displayed for legacy hearings
        expect(screen.queryByRole('heading', {name: "Transcription Details"})).toBeNull();
        expect(container.querySelector('.transcription-files-table')).toBeNull();

        // Ensure the save and cancel buttons are present
        expect(screen.getByRole('button', {name: "Cancel"})).toBeInTheDocument();
        expect(screen.getByRole('button', {name: "Save"})).toBeInTheDocument();

        expect(asFragment()).toMatchSnapshot();
      });
    });


    describe('webex hearing', () => {
      test('Displays transcription section, including transcription files table, for AMA hearings', () => {
        const {container} = customRender(
          <Details
            hearing={defaultHearing}
            saveHearing={saveHearingSpy}
            setHearing={setHearingSpy}
            goBack={goBackSpy}
            onReceiveAlerts={onReceiveAlertsSpy}
            onReceiveTransitioningAlert={onReceiveTransitioningAlertSpy}
            transitionAlert={transitionAlertSpy}
          />,
          {
            wrapper: Wrapper,
            wrapperProps: {
              store: detailsStore,
              user: anyUser,
              hearing: amaWebexHearing
            },
          }
        );

        expect(screen.getByRole('heading', {name: "Transcription Details"})).toBeInTheDocument();
        expect(screen.getByTestId('transcription-details-inputs')).toBeInTheDocument();
        expect(screen.getByTestId('transcription-details-date-inputs')).toBeInTheDocument();
        expect(screen.getByTestId('transcription-problem-inputs')).toBeInTheDocument();
        expect(screen.getByTestId('transcription-request-inputs')).toBeInTheDocument();
        expect(container.querySelector('.transcription-files-table')).toBeInTheDocument();
      });

      test('Only displays transcription files table, and not other transcription form inputs, for legacy hearings', () => {
        const {container} = customRender(
          <Details
            hearing={legacyWebexHearing}
            saveHearing={saveHearingSpy}
            setHearing={setHearingSpy}
            goBack={goBackSpy}
            onReceiveAlerts={onReceiveAlertsSpy}
            onReceiveTransitioningAlert={onReceiveTransitioningAlertSpy}
            transitionAlert={transitionAlertSpy}
          />,
          {
            wrapper: Wrapper,
            wrapperProps: {
              store: detailsStore,
              user: anyUser,
              hearing:legacyWebexHearing
            },
          }
        );

        expect(screen.getByRole('heading', {name: "Transcription Details"})).toBeInTheDocument();
        expect(screen.queryByTestId('transcription-details-inputs')).toBeNull();
        expect(screen.queryByTestId('transcription-details-date-inputs')).toBeNull();
        expect(screen.queryByTestId('transcription-problem-inputs')).toBeNull();
        expect(screen.queryByTestId('transcription-request-inputs')).toBeNull();
        expect(container.querySelector('.transcription-files-table')).toBeInTheDocument();
      });
    });
  });

  test('Displays VirtualHearing details when there is a virtual hearing', () => {
    const {asFragment} = customRender(
      <Details
        hearing={amaHearing}
        saveHearing={saveHearingSpy}
        setHearing={setHearingSpy}
        goBack={goBackSpy}
        onReceiveAlerts={onReceiveAlertsSpy}
        onReceiveTransitioningAlert={onReceiveTransitioningAlertSpy}
        transitionAlert={transitionAlertSpy}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          store: detailsStore,
          user: anyUser,
          hearing: amaHearing
        },
      }
    );

    // Ensure that the virtualHearing form is not displayed by default
    expect(screen.queryByRole('heading', {name: "Virtual Hearing Links"})).toBeNull();
    expect(screen.getByText(convertRegex(amaHearing.virtualHearing.appellantEmail))).toBeInTheDocument();
    expect(screen.getByText(convertRegex(amaHearing.virtualHearing.appellantEmail))).toBeInTheDocument();
    expect(screen.getByText(convertRegex(amaHearing.virtualHearing.representativeEmail))).toBeInTheDocument();
    expect(screen.getByText(convertRegex(amaHearing.virtualHearing.aliasWithHost))).toBeInTheDocument();
    expect(screen.getByText(convertRegex(amaHearing.virtualHearing.guestPin))).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });
});
