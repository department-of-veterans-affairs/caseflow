import React from 'react';

import { DetailsHeader } from 'app/hearings/components/details/DetailsHeader';
import { HearingConversion } from 'app/hearings/components/HearingConversion';
import { TranscriptionFormSection } from 'app/hearings/components/details/TranscriptionFormSection';
import { VirtualHearingForm } from 'app/hearings/components/details/VirtualHearingForm';
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';
import { mount } from 'enzyme';
import {
  userWithVirtualHearingsFeatureEnabled,
  userWithConvertCentralHearingsEnabled,
  legacyHearing,
  amaHearing,
  defaultHearing,
  userUseFullPageVideoToVirtual,
} from 'test/data';
import Button from 'app/components/Button';
import DateSelector from 'app/components/DateSelector';
import Details from 'app/hearings/components/Details';
import DetailsForm from 'app/hearings/components/details/DetailsForm';
import HearingTypeDropdown from 'app/hearings/components/details/HearingTypeDropdown';
import SearchableDropdown from 'app/components/SearchableDropdown';
import TranscriptionRequestInputs from
  'app/hearings/components/details/TranscriptionRequestInputs';
import VirtualHearingModal from 'app/hearings/components/VirtualHearingModal';
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

    expect(toJson(details, { noKey: true })).toMatchSnapshot();
  });

  test('Displays HearingConversion when converting from video and feature flag enabled', () => {
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
          userUseFullPageVideoToVirtual,
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

    expect(toJson(details, { noKey: true })).toMatchSnapshot();
  });

  test('Does not display VirtualHearingModal when updating transcription details with AMA virtual hearing', () => {
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
    expect(details.exists(VirtualHearingModal)).toEqual(false);

    expect(toJson(details, { noKey: true })).toMatchSnapshot();
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
    detailButtonsTest(details);

    expect(toJson(details, { noKey: true })).toMatchSnapshot();
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

    expect(toJson(details, { noKey: true })).toMatchSnapshot();
  });
});
