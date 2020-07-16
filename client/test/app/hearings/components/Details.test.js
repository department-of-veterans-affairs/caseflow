import React from 'react';

import { EmailNotificationHistory } from 'app/hearings/components/details/EmailNotificationHistory';
import { TranscriptionFormSection } from 'app/hearings/components/details/TranscriptionFormSection';
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';
import { mount } from 'enzyme';
import DetailsForm from 'app/hearings/components/details/DetailsForm';
import HearingTypeDropdown from 'app/hearings/components/details/HearingTypeDropdown';
import {
  userWithVirtualHearingsFeatureEnabled,
  userWithConvertCentralHearingsEnabled,
  legacyHearing,
  amaHearing,
  defaultHearing,
  centralHearing,
} from 'test/data';
import Details from 'app/hearings/components/Details';
import { DetailsHeader } from 'app/hearings/components/details/DetailsHeader';
import { VirtualHearingForm } from 'app/hearings/components/details/VirtualHearingForm';
import Button from 'app/components/Button';
import SearchableDropdown from 'app/components/SearchableDropdown';
import VirtualHearingModal from 'app/hearings/components/VirtualHearingModal';
import { HearingConversion } from 'app/hearings/components/HearingConversion';

// Define the function spies
const saveHearingSpy = jest.fn();
const setHearingSpy = jest.fn();
const goBackSpy = jest.fn();
const onReceiveAlertsSpy = jest.fn();
const onReceiveTransitioningAlertSpy = jest.fn();
const transitionAlertSpy = jest.fn();

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
          userWithVirtualHearingsFeatureEnabled,
          defaultHearing
        ),
        wrappingComponentProps: { store: detailsStore },
      }
    );

    // Assertions
    expect(details.find(DetailsHeader)).toHaveLength(1);
    expect(details.find(DetailsForm)).toHaveLength(1);

    // Ensure that the virtualHearing form is not displayed by default
    expect(details.find(VirtualHearingForm).prop('virtualHearing')).toEqual(
      null
    );
    expect(details.find(VirtualHearingForm).children()).toHaveLength(0);

    // Ensure the transcription section is displayed by default for ama hearings
    expect(details.find(TranscriptionFormSection)).toHaveLength(1);

    // Ensure the save and cancel buttons are present
    details.find(Button).map((node, i) => {
      // Expect the cancel button first
      if (i === 0) {
        return expect(node.prop('name')).toEqual('Cancel');
      }

      return expect(node.prop('name')).toEqual('Save');
    });

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
          userWithConvertCentralHearingsEnabled,
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
    expect(details.find(VirtualHearingModal)).toHaveLength(0);
    expect(details.find(HearingConversion)).toHaveLength(1);

    expect(details).toMatchSnapshot();
  });

  test('Displays VirtualHearingModal when converting from video', () => {
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
          userWithVirtualHearingsFeatureEnabled,
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
    expect(details.find(VirtualHearingModal)).toHaveLength(1);
    expect(details.find(HearingConversion)).toHaveLength(0);

    expect(details).toMatchSnapshot();
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
          userWithVirtualHearingsFeatureEnabled,
          legacyHearing
        ),
        wrappingComponentProps: { store: detailsStore },
      }
    );

    // Assertions
    expect(details.find(DetailsHeader)).toHaveLength(1);
    expect(details.find(DetailsForm)).toHaveLength(1);

    // Ensure that the virtualHearing form is not displayed by default
    expect(details.find(VirtualHearingForm).prop('virtualHearing')).toEqual(
      null
    );
    expect(details.find(VirtualHearingForm).children()).toHaveLength(0);

    // Ensure the transcription form is not displayed for legacy hearings
    expect(details.find(TranscriptionFormSection)).toHaveLength(0);

    // Ensure the save and cancel buttons are present
    details.find(Button).map((node, i) => {
      // Expect the cancel button first
      if (i === 0) {
        return expect(node.prop('name')).toEqual('Cancel');
      }

      return expect(node.prop('name')).toEqual('Save');
    });
    expect(details).toMatchSnapshot();
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
          userWithVirtualHearingsFeatureEnabled,
          amaHearing
        ),
        wrappingComponentProps: { store: detailsStore },
      }
    );

    // Ensure that the virtualHearing form is not displayed by default
    expect(details.find(VirtualHearingForm).prop('virtualHearing')).toEqual(
      amaHearing.virtualHearing
    );
    expect(details.find(VirtualHearingForm).children().length).toBeGreaterThan(
      0
    );

    expect(details).toMatchSnapshot();
  });
});
