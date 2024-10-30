import React from 'react';

import { HearingTypeConversionForm } from 'app/hearings/components/HearingTypeConversionForm';

import { mount } from 'enzyme';
import { legacyAppealForTravelBoard, veteranInfoWithoutEmail } from 'test/data';
import { VirtualHearingSection } from 'app/hearings/components/VirtualHearings/Section';
import { AddressLine } from 'app/hearings/components/details/Address';
import { HearingEmail } from 'app/hearings/components/details/HearingEmail';
import { getAppellantTitle } from 'app/hearings/utils';

import COPY from 'COPY';

describe('HearingTypeConversionForm', () => {
  test('Matches snapshot with default props', () => {
    const hearingTypeConversionForm = mount(
      <HearingTypeConversionForm
        appeal={legacyAppealForTravelBoard}
        type="Virtual"
      />
    );

    // Assertions
    expect(hearingTypeConversionForm.find(VirtualHearingSection)).toHaveLength(2);
    expect(hearingTypeConversionForm.find(AddressLine)).toHaveLength(1);
    expect(hearingTypeConversionForm.find(HearingEmail)).toHaveLength(2);
    expect(hearingTypeConversionForm).toMatchSnapshot();
  });

  test('Does not show a divider on top of Appellant Section', () => {
    const hearingTypeConversionForm = mount(
      <HearingTypeConversionForm
        appeal={legacyAppealForTravelBoard}
        type="Virtual"
      />
    );

    expect(
      hearingTypeConversionForm.
        findWhere(
          (node) => node.prop('label') === `${getAppellantTitle(legacyAppealForTravelBoard.appellantIsNotVeteran)}`
        ).
        prop('showDivider')
    ).toEqual(false);
    expect(hearingTypeConversionForm.find('.cf-help-divider')).toHaveLength(1);
    expect(hearingTypeConversionForm).toMatchSnapshot();
  });

  test('Display missing email alert', () => {
    const appeal = {
      ...legacyAppealForTravelBoard,
      veteranInfo: {
        ...veteranInfoWithoutEmail
      }
    };

    const hearingTypeConversionForm = mount(
      <HearingTypeConversionForm
        appeal={appeal}
        type="Virtual"
      />
    );

    expect(hearingTypeConversionForm.find('.usa-alert')).toHaveLength(1);
    expect(hearingTypeConversionForm).toMatchSnapshot();
  });

  test('Displays "the appropriate regional office" when closest regional office has not been determined yet', () => {
    const appeal = {
      ...legacyAppealForTravelBoard,
      closestRegionalOfficeLabel: null
    };

    const hearingTypeConversionForm = mount(
      <HearingTypeConversionForm
        appeal={appeal}
        type="Virtual"
      />
    );

    expect(
      hearingTypeConversionForm.
        find('p').
        first().
        text().
        includes(COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT)
    ).toEqual(true);
    expect(hearingTypeConversionForm).toMatchSnapshot();
  });
});

