import React from 'react';
import { detailsStore } from 'test/data/stores/hearingsStore';
import { screen } from '@testing-library/react';
import DetailsForm from 'app/hearings/components/details/DetailsForm';
import { anyUser, amaHearing, defaultHearing } from 'test/data';
import { Wrapper, customRender } from '../../../../helpers/testHelpers';

describe('DetailsForm', () => {
  test('Matches snapshot with default props when passed in', async () => {
    const { asFragment } = customRender(
      <DetailsForm
      hearing={defaultHearing}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: { user: anyUser, hearing: amaHearing, store: detailsStore }
      }
    );

    expect(asFragment()).toMatchSnapshot();

    const element = document.getElementById('hearingEmailEvents');
    expect(element).not.toBeInTheDocument();
  });

  test('Matches snapshot with for legacy hearing', () => {
    const { asFragment } = customRender(
      <DetailsForm
      isLegacy
      hearing={defaultHearing}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: { user: anyUser, hearing: amaHearing, store: detailsStore }
      }
    );

    expect(asFragment()).toMatchSnapshot();

    const hearingTypeInput = screen.getByRole('combobox', { name: /hearing type/i });
    expect(hearingTypeInput).toBeInTheDocument();

    const transcriptionDetails = screen.queryByText('Transcription Details');
    expect(transcriptionDetails).not.toBeInTheDocument
  });

  test('Matches snapshot with for AMA hearing', () => {
    const { asFragment } = customRender(
      <DetailsForm
      isLegacy={false}
      hearing={defaultHearing}
      />,
      {
        wrapper: Wrapper,
        wrapperProps: { user: anyUser, hearing: amaHearing, store: detailsStore }
      }
    );

    expect(asFragment()).toMatchSnapshot();

    const hearingTypeInput = screen.getByRole('combobox', { name: /hearing type/i });
    expect(hearingTypeInput).toBeInTheDocument();

    const transcriptionDetails = screen.getByRole('heading', { name: /transcription details/i });
    expect(transcriptionDetails).toBeInTheDocument();

    const checkbox = screen.getByRole('checkbox', { name: /evidenceWindowWaived/i });
    expect(checkbox).toBeInTheDocument();
  });
});
