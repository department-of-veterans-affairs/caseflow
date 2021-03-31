import React from 'react';

import { LEGACY_APPEAL_TYPES } from 'app/queue/constants';
import { AppealInformation } from 'app/hearings/components/scheduleHearing/AppealInformation';
import { render, screen } from '@testing-library/react';
import { amaAppeal, powerOfAttorney } from 'test/data/appeals';

describe('AppealInformation', () => {
  test('Matches snapshot with default props', () => {
    // Run the test
    const info = render(
      <AppealInformation appeal={{ ...amaAppeal, powerOfAttorney }} />
    );

    // Check that the labels are all there
    expect(screen.queryAllByText('Veteran Name')).toHaveLength(1);
    expect(screen.queryAllByText('Issues')).toHaveLength(1);
    expect(screen.queryAllByText('Appeal Stream')).toHaveLength(1);
    expect(screen.queryAllByText('Docket Number')).toHaveLength(1);
    expect(screen.queryAllByText('Power of Attorney')).toHaveLength(1);
    expect(screen.queryAllByText('Date of Death')).toHaveLength(0);

    // Check that all the values are correct
    expect(screen.queryAllByText(amaAppeal.veteranFullName)).toHaveLength(1);
    expect(screen.queryAllByText('Original')).toHaveLength(1);
    expect(screen.queryAllByText(amaAppeal.docketNumber)).toHaveLength(1);
    expect(
      screen.queryAllByText(powerOfAttorney.representative_name)
    ).toHaveLength(1);

    expect(info).toMatchSnapshot();
  });

  test('Displays date of death when present', () => {
    // Example date of death
    const dod = '01/01/2021';

    // Run the test
    const info = render(
      <AppealInformation appeal={{ ...amaAppeal, veteranDateOfDeath: dod, powerOfAttorney }} />
    );

    // Check that the labels are all there
    expect(screen.queryAllByText('Date of Death')).toHaveLength(1);

    // Check that all the values are correct
    expect(screen.queryAllByText(dod)).toHaveLength(1);

    expect(info).toMatchSnapshot();
  });

  test('Displays veteran name when appellant is the veteran', () => {
    // Run the test
    const info = render(
      <AppealInformation appeal={{ ...amaAppeal, appellantIsNotVeteran: true }} />
    );

    // Check that the labels are all there
    expect(screen.queryAllByText('Appellant Name')).toHaveLength(1);

    // Check that all the values are correct
    expect(screen.queryAllByText(amaAppeal.appellantFullName)).toHaveLength(1);

    expect(info).toMatchSnapshot();
  });

  test('Displays AOD docket when appellant is advanced on the docket', () => {
    // Run the test
    const info = render(
      <AppealInformation appeal={{ ...amaAppeal, isAdvancedOnDocket: true, powerOfAttorney }} />
    );

    // Check that the labels are all there
    expect(screen.queryAllByText('AOD')).toHaveLength(1);

    expect(info).toMatchSnapshot();
  });

  test('Displays source appeal link when case type is CAVC remand', () => {
    // Setup the test
    const remandJudgeName = 'Judge Name';
    const remandSourceAppealId = '123';
    const cavcRemand = {};

    // Run the test
    const info = render(
      <AppealInformation
        appeal={{
          ...amaAppeal,
          cavcRemand,
          remandJudgeName,
          remandSourceAppealId,
          caseType: LEGACY_APPEAL_TYPES.CAVC_REMAND,
          powerOfAttorney,
        }}
      />
    );

    // Check that the labels are all there
    expect(screen.queryAllByText('CAVC')).toHaveLength(1);
    expect(screen.queryAllByText(`VLJ ${remandJudgeName}`)).toHaveLength(1);
    expect(
      screen.getByText(LEGACY_APPEAL_TYPES.CAVC_REMAND).closest('a')
    ).toHaveAttribute('href', `/queue/appeals/${remandSourceAppealId}`);

    expect(info).toMatchSnapshot();
  });

  test('Displays no representative when POA is null', () => {
    // Run the test
    const info = render(<AppealInformation appeal={amaAppeal} />);

    // Check that the labels are all there
    expect(screen.queryAllByText('No representative')).toHaveLength(1);

    expect(info).toMatchSnapshot();
  });
});
