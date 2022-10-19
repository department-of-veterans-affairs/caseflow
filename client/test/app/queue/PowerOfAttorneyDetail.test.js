import React from 'react';

import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import { applyMiddleware, createStore, compose } from 'redux';

import { PowerOfAttorneyDetailUnconnected } from 'app/queue/PowerOfAttorneyDetail';

import { amaAppeal as appeal, powerOfAttorney } from 'test/data/appeals';
import { APPELLANT_TYPES } from 'app/queue/constants';

const createQueueReducer = (storeValues) => {
  return (state = storeValues) => {

    return state;
  };
};

const renderPowerOfAttorneyDetailUnconnected = (storeValues, appellantType) => {

  const queueReducer = createQueueReducer(storeValues);

  const store = createStore(
    queueReducer,
    compose(applyMiddleware(thunk))
  );

  return render(
    <Provider store={store}>
      <MemoryRouter>
        <PowerOfAttorneyDetailUnconnected
          appealId={Object.keys(storeValues.queue.appeals)[0]}
          appellantType={appellantType}
          poaAlert={storeValues.ui.poaAlert}
          powerOfAttorney={powerOfAttorney}
        />
      </MemoryRouter>
    </Provider>
  );
};

const createStoreValues = (hasPOA, appellantType, editPOAInformation) => {
  return {
    queue: {
      appeals: {
        ...appeal,
        hasPOA,
        appellantType,
        ...powerOfAttorney,
      }
    },
    ui: {
      poaAlert: {
        message: 'Info banner message',
        alertType: 'info',
        powerOfAttorney
      },
      featureToggles: {
        poa_button_refresh: true
      }
    },
    editPOAInformation
  };
};

describe('POA Refresh button', () => {
  test('Does not appear if claimant is an OtherClaimant', () => {
    const storeValues = createStoreValues(true, APPELLANT_TYPES.OTHER_CLAIMANT, false);

    renderPowerOfAttorneyDetailUnconnected(storeValues, APPELLANT_TYPES.OTHER_CLAIMANT);

    expect(screen.queryByText('Refresh POA')).not.toBeTruthy();
  });

  test('Does not appear if claimant is a HealthcareProviderClaimant', () => {
    const storeValues = createStoreValues(true, APPELLANT_TYPES.HEALTHCARE_PROVIDER_CLAIMANT, false);

    renderPowerOfAttorneyDetailUnconnected(storeValues, APPELLANT_TYPES.HEALTHCARE_PROVIDER_CLAIMANT);

    expect(screen.queryByText('Refresh POA')).not.toBeTruthy();
  });

  test('Appears if claimant is a VeteranClaimant', () => {
    const storeValues = createStoreValues(true, APPELLANT_TYPES.VETERAN_CLAIMANT, false);

    renderPowerOfAttorneyDetailUnconnected(storeValues, APPELLANT_TYPES.VETERAN_CLAIMANT);

    expect(screen.queryByText('Refresh POA')).toBeTruthy();
  });
});
