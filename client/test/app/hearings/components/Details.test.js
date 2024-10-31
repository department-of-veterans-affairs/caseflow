import React from 'react';

import { DetailsHeader } from 'app/hearings/components/details/DetailsHeader';
import { HearingConversion } from 'app/hearings/components/HearingConversion';
import { TranscriptionFormSection } from 'app/hearings/components/details/TranscriptionFormSection';
import { VirtualHearingFields } from 'app/hearings/components/details/VirtualHearingFields';
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';
import { mount } from 'enzyme';
import {
  anyUser,
  legacyHearing,
  amaHearing,
  defaultHearing,
  virtualHearing,
  amaWebexHearing,
  legacyWebexHearing
} from 'test/data';
import Button from 'app/components/Button';
import DateSelector from 'app/components/DateSelector';
import Details from 'app/hearings/components/Details';
import DetailsForm from 'app/hearings/components/details/DetailsForm';
import HearingTypeDropdown from 'app/hearings/components/details/HearingTypeDropdown';
import SearchableDropdown from 'app/components/SearchableDropdown';
import TranscriptionDetailsInputs from 'app/hearings/components/details/TranscriptionDetailsInputs';
import TranscriptionProblemInputs from 'app/hearings/components/details/TranscriptionProblemInputs';
import TranscriptionRequestInputs from 'app/hearings/components/details/TranscriptionRequestInputs';
import TranscriptionDetailsWebex from '../../../../app/hearings/components/details/TranscriptionDetailsWebex';
import TranscriptionFilesTable from 'app/hearings/components/details/TranscriptionFilesTable';
import EmailConfirmationModal from 'app/hearings/components/EmailConfirmationModal';
import toJson from 'enzyme-to-json';

// Define the function spies
const saveHearingSpy = jest.fn();
const setHearingSpy = jest.fn();
const goBackSpy = jest.fn();
const onReceiveAlertsSpy = jest.fn();
const onReceiveTransitioningAlertSpy = jest.fn();
const transitionAlertSpy = jest.fn();

const detailButtonsTest = (node) => {
  node.find(Button).map((n, i) => {
    // Expect the cancel button first
    if (i === 0) {
      return expect(n.prop('name')).toEqual('Cancel');
    }

    return expect(n.prop('name')).toEqual('Save');
  });
};

describe('Details', () => {
  test('Matches snapshot with default props', () => {
    const details = mount(
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
        wrappingComponent: hearingDetailsWrapper(
          anyUser,
          defaultHearing
        ),
        wrappingComponentProps: { store: detailsStore },
      }
    );

    // Assertions
    expect(details.find(DetailsHeader)).toHaveLength(1);
    expect(details.find(DetailsForm)).toHaveLength(1);

    // Ensure that the virtualHearing form is not displayed by default
    expect(details.find(VirtualHearingFields).prop('virtualHearing')).toEqual(
      null
    );
    // VirtualHearingFields will always show for any virtual or non virtual hearing
    // as we move forward with Webex integration
    expect(details.find(VirtualHearingFields).children()).toHaveLength(1);

    // Ensure the transcription section is displayed by default for ama hearings
    expect(details.find(TranscriptionFormSection)).toHaveLength(1);

    // Ensure the save and cancel buttons are present
    detailButtonsTest(details);

    expect(details).toMatchSnapshot();
  });

  test('Displays HearingConversion when converting from central', () => {
    const details = mount(
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
        wrappingComponent: hearingDetailsWrapper(
          anyUser,
          amaHearing
        ),
        wrappingComponentProps: { store: detailsStore },
      }
    );
    const dropdown = details.find(HearingTypeDropdown).find(SearchableDropdown);

    // Change the value of the hearing type
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });

    // Ensure the modal is displayed
    expect(details.find(EmailConfirmationModal)).toHaveLength(0);
    expect(details.find(HearingConversion)).toHaveLength(1);

    expect(toJson(details, { noKey: true })).toMatchSnapshot();
  });

  test('Displays HearingConversion when converting from video', () => {
    const details = mount(
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
        wrappingComponent: hearingDetailsWrapper(
          anyUser,
          defaultHearing
        ),
        wrappingComponentProps: { store: detailsStore },
      }
    );
    const dropdown = details.find(HearingTypeDropdown).find(SearchableDropdown);

    // Change the value of the hearing type
    dropdown.
      find('Select').
      simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.
      find('Select').
      simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });

    // Ensure the modal is displayed
    expect(details.find(EmailConfirmationModal)).toHaveLength(0);
    expect(details.find(HearingConversion)).toHaveLength(1);

    expect(details).toMatchSnapshot();
  });

  test('Displays HearingConversion when converting from virtual', () => {
    const details = mount(
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
        wrappingComponent: hearingDetailsWrapper(
          anyUser,
          defaultHearing
        ),
        wrappingComponentProps: { store: detailsStore },
      }
    );
    const dropdown = details.find(HearingTypeDropdown).find(SearchableDropdown);

    // Change the value of the hearing type
    dropdown.
      find('Select').
      simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.
      find('Select').
      simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });

    expect(details.find(HearingConversion)).toHaveLength(1);

    expect(toJson(details, { noKey: true })).toMatchSnapshot();
  });

  test('Does not display EmailConfirmationModal when updating transcription details with AMA virtual hearing', () => {
    const details = mount(
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
        wrappingComponent: hearingDetailsWrapper(
          anyUser,
          amaHearing
        ),
        wrappingComponentProps: { store: detailsStore },
      }
    );

    // Update the transcription sent date field
    details.
      find(TranscriptionRequestInputs).
      find(DateSelector).
      find('input').
      simulate('change', { target: { value: '07/25/2020' } });

    // Click save
    details.
      find(Button).
      findWhere((node) => node.prop('name') === 'Save').
      find('button').
      simulate('click');

    // Ensure the modal is not displayed
    expect(details.exists(EmailConfirmationModal)).toEqual(false);

    expect(toJson(details, { noKey: true })).toMatchSnapshot();
  });

  describe('TranscriptiomFormSection', () => {
    describe('pexip hearing', () => {
      test('Displays transcription section but not transcription files table for AMA hearings', () => {
        const details = mount(
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
            wrappingComponent: hearingDetailsWrapper(
              anyUser,
              amaHearing
            ),
            wrappingComponentProps: { store: detailsStore },
          }
        );

        expect(details.find(TranscriptionFormSection)).toHaveLength(1);
        expect(details.find(TranscriptionDetailsInputs)).toHaveLength(1);
        expect(details.find(TranscriptionProblemInputs)).toHaveLength(1);
        expect(details.find(TranscriptionRequestInputs)).toHaveLength(1);
        expect(details.find(TranscriptionFilesTable)).toHaveLength(0);
      });

      test('Does not display transcription section for legacy hearings', () => {
        const details = mount(
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
            wrappingComponent: hearingDetailsWrapper(
              anyUser,
              legacyHearing
            ),
            wrappingComponentProps: { store: detailsStore },
          }
        );

        // Assertions
        expect(details.find(DetailsHeader)).toHaveLength(1);
        expect(details.find(DetailsForm)).toHaveLength(1);

        // Ensure that the virtualHearing form is not displayed by default
        expect(details.find(VirtualHearingFields).prop('virtualHearing')).toEqual(
          null
        );
        // VirtualHearingFields will always show for any virtual or non virtual hearing
        // as we move forward with Webex integration
        expect(details.find(VirtualHearingFields).children()).toHaveLength(1);

        // Ensure the transcription form is not displayed for legacy hearings
        expect(details.find(TranscriptionFormSection)).toHaveLength(0);
        // expect(details.find(TranscriptionFilesTable)).toHaveLength(0);

        // Ensure the save and cancel buttons are present
        detailButtonsTest(details);

        expect(toJson(details, { noKey: true })).toMatchSnapshot();
      });
    });

    describe('webex hearing', () => {
      test('Displays transcription section, including transcription files table, for AMA hearings', () => {
        const details = mount(
          <Details
            hearing={amaWebexHearing}
            saveHearing={saveHearingSpy}
            setHearing={setHearingSpy}
            goBack={goBackSpy}
            onReceiveAlerts={onReceiveAlertsSpy}
            onReceiveTransitioningAlert={onReceiveTransitioningAlertSpy}
            transitionAlert={transitionAlertSpy}
          />,
          {
            wrappingComponent: hearingDetailsWrapper(
              anyUser,
              amaWebexHearing
            ),
            wrappingComponentProps: { store: detailsStore },
          }
        );

        expect(details.find(TranscriptionFormSection)).toHaveLength(1);
        expect(details.find(TranscriptionDetailsInputs)).toHaveLength(1);
        expect(details.find(TranscriptionProblemInputs)).toHaveLength(1);
        expect(details.find(TranscriptionRequestInputs)).toHaveLength(1);
        expect(details.find(TranscriptionFilesTable)).toHaveLength(1);
      });

      test('Only displays transcription files table, and not other transcription form inputs, for legacy hearings', () => {
        const details = mount(
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
            wrappingComponent: hearingDetailsWrapper(
              anyUser,
              legacyWebexHearing
            ),
            wrappingComponentProps: { store: detailsStore },
          }
        );

        expect(details.find(TranscriptionFormSection)).toHaveLength(1);
        expect(details.find(TranscriptionDetailsInputs)).toHaveLength(0);
        expect(details.find(TranscriptionProblemInputs)).toHaveLength(0);
        expect(details.find(TranscriptionRequestInputs)).toHaveLength(0);
        expect(details.find(TranscriptionFilesTable)).toHaveLength(1);
      });
    });
  });

  test('Displays VirtualHearing details when there is a virtual hearing', () => {
    const details = mount(
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
        wrappingComponent: hearingDetailsWrapper(
          anyUser,
          amaHearing
        ),
        wrappingComponentProps: { store: detailsStore },
      }
    );

    // Ensure that the virtualHearing form is not displayed by default
    expect(details.find(VirtualHearingFields).prop('virtualHearing')).toEqual(
      amaHearing.virtualHearing
    );
    expect(details.find(VirtualHearingFields).children().length).toBeGreaterThan(
      0
    );

    expect(toJson(details, { noKey: true })).toMatchSnapshot();
  });
});
