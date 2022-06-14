import React from 'react';

import { mount } from 'enzyme';

import {
  HearingTypeConversionForm,
} from '../../../../app/hearings/components/HearingTypeConversionForm';
import { legacyAppealForTravelBoard } from '../../../data/appeals';
import { queueWrapper } from '../../../data/stores/queueStore';
import { HearingTypeConversion } from '../../../../app/hearings/components/HearingTypeConversion';
import {
  HearingTypeConversionProvider,
} from '../../../../app/hearings/contexts/HearingTypeConversionContext';

describe('HearingTypeConversion', () => {
  test('Matches snapshot with default props', () => {
    const hearingTypeConversion = mount(
      <HearingTypeConversionProvider>
        <HearingTypeConversion
          appeal={legacyAppealForTravelBoard}
          type="Virtual"
        />
      </HearingTypeConversionProvider>,
      {
        wrappingComponent: queueWrapper,
      }
    );

    expect(hearingTypeConversion.exists(HearingTypeConversionForm)).toBeTruthy();
    expect(hearingTypeConversion).toMatchSnapshot();
  });
});
