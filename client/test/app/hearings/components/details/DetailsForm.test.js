import { createStore } from 'redux';
import React from 'react';

import {
  EmailNotificationHistory,
} from 'app/hearings/components/details/EmailNotificationHistory';
import { HearingsFormContext } from 'app/hearings/contexts/HearingsFormContext';
import { HearingsUserContext } from 'app/hearings/contexts/HearingsUserContext';
import { TranscriptionFormSection } from 'app/hearings/components/details/TranscriptionFormSection';
import { WrappingComponent } from 'test/karma/establishClaim/WrappingComponent';
import { mount } from 'enzyme';
import { userWithVirtualHearingsFeatureEnabled } from 'test/data/user';
import CheckBox from 'app/components/Checkbox';
import DetailsForm from 'app/hearings/components/details/DetailsForm';
import HearingTypeDropdown from
  'app/hearings/components/details/HearingTypeDropdown';
import reducer from 'app/hearings/reducers';

const hearingsDispatch = jest.fn();
const openVirtualHearingModalMock = jest.fn();
const updateVirtualHearingMock = jest.fn();
const initialHearingFormState = {
  state: { hearingForms: {} },
  dispatch: hearingsDispatch
};
const defaultStore = createStore(
  reducer,
  {
    components: {
      dropdowns: {
        hearingCoordinators: {
          isFetching: false,
          options: []
        }
      }
    }
  }
);

describe('DetailsForm', () => {
  test('Matches snapshot with default props when passed in', () => {
    const form = mount(
      <HearingsUserContext.Provider value={userWithVirtualHearingsFeatureEnabled}>
        <HearingsFormContext.Provider value={initialHearingFormState}>
          <DetailsForm />
        </HearingsFormContext.Provider>
      </HearingsUserContext.Provider>,
      {
        wrappingComponent: WrappingComponent,
        wrappingComponentProps: { store: defaultStore }
      }
    );

    expect(form).toMatchSnapshot();
    expect(form.find(EmailNotificationHistory)).toHaveLength(0);
  });

  test('Matches snapshot with for legacy hearing', () => {
    const form = mount(
      <HearingsUserContext.Provider value={userWithVirtualHearingsFeatureEnabled}>
        <HearingsFormContext.Provider value={initialHearingFormState}>
          <DetailsForm isLegacy />
        </HearingsFormContext.Provider>
      </HearingsUserContext.Provider>,
      {
        wrappingComponent: WrappingComponent,
        wrappingComponentProps: { store: defaultStore }
      }
    );

    expect(form).toMatchSnapshot();
    expect(form.find(HearingTypeDropdown)).toHaveLength(1);
    expect(form.find(TranscriptionFormSection)).toHaveLength(0);
  });

  test('Matches snapshot with for AMA hearing', () => {
    const form = mount(
      <HearingsUserContext.Provider value={userWithVirtualHearingsFeatureEnabled}>
        <HearingsFormContext.Provider value={initialHearingFormState}>
          <DetailsForm isLegacy={false} />
        </HearingsFormContext.Provider>
      </HearingsUserContext.Provider>,
      {
        wrappingComponent: WrappingComponent,
        wrappingComponentProps: { store: defaultStore }
      }
    );

    expect(form).toMatchSnapshot();
    expect(form.find(HearingTypeDropdown)).toHaveLength(1);
    expect(form.find(TranscriptionFormSection)).toHaveLength(1);
    expect(
      form.findWhere((node) => node.props().name === 'evidenceWindowWaived' && node.type() === CheckBox)
    ).toHaveLength(1);
  });

  test(
    'Matches snapshot if user does not have the enable virtual hearings feature flag enabled',
    () => {
      const form = mount(
        <HearingsUserContext.Provider value={{ userCanScheduleVirtualHearings: false }}>
          <HearingsFormContext.Provider value={initialHearingFormState}>
            <DetailsForm />
          </HearingsFormContext.Provider>
        </HearingsUserContext.Provider>,
        {
          wrappingComponent: WrappingComponent,
          wrappingComponentProps: { store: defaultStore }
        }
      );

      expect(form).toMatchSnapshot();
      expect(form.find(HearingTypeDropdown)).toHaveLength(0);
    }
  );
});
