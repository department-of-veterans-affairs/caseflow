import React from 'react';

import { mount } from 'enzyme';

import {
  HearingTypeConversionForm,
} from '../../../../app/hearings/components/HearingTypeConversionForm';
import { legacyAppealForTravelBoard } from '../../../data/appeals';
import { queueWrapper } from '../../../data/stores/queueStore';
import HearingTypeConversion from
  '../../../../app/hearings/components/HearingTypeConversion';

describe('HearingTypeConversion', () => {
  test('Matches snapshot with default props', () => {
    const hearingTypeConversion = mount(
      <HearingTypeConversion
        appeal={legacyAppealForTravelBoard}
        type={'Virtual'}
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    expect(hearingTypeConversion.exists(HearingTypeConversionForm)).toBeTruthy();
    expect(hearingTypeConversion).toMatchSnapshot();
  });
});
