import React from 'react';
import { render, screen } from '@testing-library/react';

import { AppellantDetail } from 'app/queue/AppellantDetail';

import { appealData as appeal } from 'test/data/appeals';
import { APPELLANT_TYPES } from 'app/queue/constants';
import COPY from '../../../COPY';

const renderAppellantDetail = (appealData) => {

  return render(
    <AppellantDetail appeal={{ ...appealData }} />
  );
};

describe('editNotice', () => {
  test('editNotice is displayed whenever appellantType is "OtherClaimant"', () => {
    renderAppellantDetail(
      {
        ...appeal,
        appellantType: APPELLANT_TYPES.OTHER_CLAIMANT
      }
    );

    expect(screen.queryByText(COPY.CASE_DETAILS_UNRECOGNIZED_APPELLANT)).toBeTruthy();
    expect(screen.queryByText(COPY.CASE_DETAILS_UNRECOGNIZED_ATTORNEY_APPELLANT)).not.toBeTruthy();
  });

  test('editNotice is displayed whenever appellantType is "HealthcareProviderClaimant"', () => {
    renderAppellantDetail(
      {
        ...appeal,
        appellantType: APPELLANT_TYPES.HEALTHCARE_PROVIDER_CLAIMANT
      }
    );

    expect(screen.queryByText(COPY.CASE_DETAILS_UNRECOGNIZED_APPELLANT)).toBeTruthy();
    expect(screen.queryByText(COPY.CASE_DETAILS_UNRECOGNIZED_ATTORNEY_APPELLANT)).not.toBeTruthy();
  });

  test('Attorney editNotice is displayed whenever appellantType is "AttorneyClaimant"', () => {
    renderAppellantDetail(
      {
        ...appeal,
        appellantType: APPELLANT_TYPES.ATTORNEY_CLAIMANT

      }
    );

    expect(screen.queryByText(COPY.CASE_DETAILS_UNRECOGNIZED_APPELLANT)).not.toBeTruthy();
    expect(screen.queryByText(COPY.CASE_DETAILS_UNRECOGNIZED_ATTORNEY_APPELLANT)).toBeTruthy();
  });

  test('editNotice is not displayed whenever appellantType is "VeteranClaimant"', () => {
    renderAppellantDetail(
      {
        ...appeal,
        appellantType: APPELLANT_TYPES.VETERAN_CLAIMANT
      }
    );

    expect(screen.queryByText(COPY.CASE_DETAILS_UNRECOGNIZED_APPELLANT)).not.toBeTruthy();
    expect(screen.queryByText(COPY.CASE_DETAILS_UNRECOGNIZED_ATTORNEY_APPELLANT)).not.toBeTruthy();
  });
});
