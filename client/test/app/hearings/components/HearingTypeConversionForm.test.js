import React from 'react';
import { HearingTypeConversionForm } from 'app/hearings/components/HearingTypeConversionForm';
import { render, screen} from '@testing-library/react';
import { legacyAppealForTravelBoard, veteranInfoWithoutEmail } from 'test/data';
import { getAppellantTitle } from 'app/hearings/utils';

import COPY from 'COPY';

describe('HearingTypeConversionForm', () => {
  test('Matches snapshot with default props', () => {
   const {asFragment}=render(
      <HearingTypeConversionForm
        appeal={legacyAppealForTravelBoard}
        type="Virtual"
      />
    );

    // Assertions
    expect(screen.getByRole('heading', {name: "Veteran"})).toBeInTheDocument();
    expect(screen.getByRole('heading', {name: "Power of Attorney (POA)"})).toBeInTheDocument();

    expect(screen.getByText('Clarence Darrow')).toBeInTheDocument();

    expect(screen.getByText(/Veteran Email/i)).toBeInTheDocument();
    const poaRegex = new RegExp('POA\\/Representative Email', 'i');
    expect(screen.getByText(poaRegex)).toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Does not show a divider on top of Appellant Section', () => {
    const {asFragment, container}=render(
      <HearingTypeConversionForm
        appeal={legacyAppealForTravelBoard}
        type="Virtual"
      />
    );

    const element = screen.getByText(getAppellantTitle(legacyAppealForTravelBoard.appellantIsNotVeteran));
    const previousElement = element.previousElementSibling;
    expect(previousElement).not.toHaveClass('cf-help-divider');
    expect(container.querySelectorAll('.cf-help-divider')).toHaveLength(1);

    expect(asFragment()).toMatchSnapshot();
  });

  test('Display missing email alert', () => {
    const appeal = {
      ...legacyAppealForTravelBoard,
      veteranInfo: {
        ...veteranInfoWithoutEmail
      }
    };

    const {asFragment, container}=render(
      <HearingTypeConversionForm
        appeal={appeal}
        type="Virtual"
      />
    );

    expect(container.querySelectorAll('.usa-alert')).toHaveLength(1);
    expect(asFragment()).toMatchSnapshot();
  });

  test('Displays "the appropriate regional office" when closest regional office has not been determined yet', () => {
    const appeal = {
      ...legacyAppealForTravelBoard,
      closestRegionalOfficeLabel: null
    };

    const {asFragment}=render(
      <HearingTypeConversionForm
        appeal={appeal}
        type="Virtual"
      />
    );

    const string = COPY.CONVERT_HEARING_TYPE_SUBTITLE.
    replace('%s', COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT);
    expect(screen.getByText(string)).toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });
});

