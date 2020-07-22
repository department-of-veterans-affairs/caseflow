import React from 'react';
import { mount } from 'enzyme';

import VirtualHearingModal, { ChangeToVirtual } from 'app/hearings/components/VirtualHearingModal';
import { defaultHearing, userWithVirtualHearingsFeatureEnabled, virtualHearing } from 'test/data';
import { HEARING_CONVERSION_TYPES } from 'app/hearings/constants';
import { detailsStore, hearingDetailsWrapper } from 'test/data/stores/hearingsStore';
import Button from 'app/components/Button';

// Setup the test constants
const updateSpy = jest.fn();

describe('VirtualHearingModal', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const modal = mount(
      <VirtualHearingModal
        update={updateSpy}
        hearing={defaultHearing}
        virtualHearing={virtualHearing.virtualHearing}
        type={HEARING_CONVERSION_TYPES[0]}
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
    expect(modal.find(ChangeToVirtual)).toHaveLength(1);
    expect(modal.find(Button).first().
      text()).toEqual('Change and Send Email');
    expect(modal.find(Button).at(1).
      text()).toEqual('Cancel');
    expect(modal).toMatchSnapshot();
  });
});
