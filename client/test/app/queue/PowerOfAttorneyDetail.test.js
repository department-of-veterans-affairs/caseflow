import React from 'react';

import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import { applyMiddleware, createStore, compose } from 'redux';

import PowerOfAttorneyDetail from 'app/queue/PowerOfAttorneyDetail';

import { amaAppeal as appeal, powerOfAttorney } from 'test/data/appeals';
import { APPELLANT_TYPES } from 'app/queue/constants';
import COPY from '../../../COPY';

const createQueueReducer = (storeValues) => {
  return (state = storeValues) => {

    return state;
  };
};

const renderPowerOfAttorneyDetail = (storeValues, appellantType) => {

  const queueReducer = createQueueReducer(storeValues);

  const store = createStore(
    queueReducer,
    compose(applyMiddleware(thunk))
  );

  return render(
    <Provider store={store}>
      <MemoryRouter>
        <PowerOfAttorneyDetail
          title={COPY.CASE_DETAILS_POA_SUBSTITUTE}
          appealId={Object.keys(storeValues.queue.appeals)[0]}
          appellantType={appellantType}
        />
      </MemoryRouter>
    </Provider>
  );
};

const queueStoreValues = {
  loadingAppealDetail: {
    [appeal.externalId]: {
      powerOfAttorney: {
        loading: false
      },
      veteranInfo: {
        loading: false
      }
    }
  }
};

const createStoreValues = (hasPOA, appellantType, poaAlert, editPOAInformation) => {
  return {
    queue: {
      ...queueStoreValues,
      appeals: {
        ...appeal,
        hasPOA,
        appellantType,
        ...powerOfAttorney,
      }
    },
    ui: {
      poaAlert
    },
    editPOAInformation
  };
};

describe('POA Refresh button', () => {
  test('Does not appear if claimant is an OtherClaimant', () => {
    const storeValues = createStoreValues(false, APPELLANT_TYPES.OTHER_CLAIMANT, false, false);

    renderPowerOfAttorneyDetail(storeValues, APPELLANT_TYPES.OTHER_CLAIMANT);

    expect(screen.queryByText('POA Refresh')).not.toBeTruthy();
  });

  test('Does not appear if claimant is a HealthcareProviderClaimant', () => {
    const storeValues = createStoreValues(false, APPELLANT_TYPES.HEALTHCARE_PROVIDER_CLAIMANT, false, false);

    renderPowerOfAttorneyDetail(storeValues, APPELLANT_TYPES.OTHER_CLAIMANT);

    expect(screen.queryByText('POA Refresh')).not.toBeTruthy();
  });
});
