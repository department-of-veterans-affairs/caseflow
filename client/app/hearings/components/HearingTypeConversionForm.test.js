import React from 'react';

import { HearingTypeConversionForm } from 'app/hearings/components/HearingTypeConversionForm';

import { mount } from 'enzyme';
import { amaAppealForTravelBoard } from 'test/data';
import { VirtualHearingSection } from 'app/hearings/components/VirtualHearings/Section';
import { AddressLine } from 'app/hearings/components/details/Address';
import { VirtualHearingEmail } from 'app/hearings/components/VirtualHearings/Emails';
import { getAppellantTitle } from 'app/hearings/utils';

describe('HearingTypeConversionForm', () => {
  test('Matches snapshot with default props', () => {
    const hearingTypeConversionForm = mount(
      <HearingTypeConversionForm
        appeal={amaAppealForTravelBoard}
        type={'Virtual'}
      />
    );

    // Assertions
    expect(hearingTypeConversionForm.find(VirtualHearingSection)).toHaveLength(2);
    expect(hearingTypeConversionForm.find(AddressLine)).toHaveLength(1);
    expect(hearingTypeConversionForm.find(VirtualHearingEmail)).toHaveLength(2);
    expect(hearingTypeConversionForm).toMatchSnapshot();
  });

  test('Does not show a divider on top of Appellant Section', () => {
    const hearingTypeConversionForm = mount(
      <HearingTypeConversionForm
        appeal={amaAppealForTravelBoard}
        type={'Virtual'}
      />
    )

    expect(
      hearingTypeConversionForm.
        findWhere(
          (node) => node.prop('label') === `${getAppellantTitle(amaAppealForTravelBoard.appellantIsNotVeteran)}`
        ).
        prop('showDivider')
    ).toEqual(false);
    expect(hearingTypeConversionForm.find('.cf-help-divider')).toHaveLength(1);
    expect(hearingTypeConversionForm).toMatchSnapshot();
  });
});

