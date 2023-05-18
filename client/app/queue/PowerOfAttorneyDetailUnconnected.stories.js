import React from 'react';

import { MemoryRouter } from 'react-router';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import { applyMiddleware, createStore, compose } from 'redux';

import { PowerOfAttorneyDetailUnconnected } from 'app/queue/PowerOfAttorneyDetail';

import { amaAppeal as appeal, powerOfAttorney } from 'test/data/appeals';
import { APPELLANT_TYPES } from 'app/queue/constants';

export default {
  title: 'Queue/Case Details/PowerOfAttorneyDetail/PowerOfAttorneyDetailUnconnected',
  component: PowerOfAttorneyDetailUnconnected,
  parameters: { controls: { expanded: true } },
};

const createReducer = (storeValues) => {
  return function(state = storeValues) {

    return state;
  };
};

const Template = (args) => {
  const store = createStore(
    createReducer({ ...args }),
    compose(applyMiddleware(thunk))
  );

  const appealId = Object.keys(args.queue.appeals)[0];

  return (
    <Provider store={store}>
      <MemoryRouter>
        <PowerOfAttorneyDetailUnconnected
          appellantType={args.queue.appeals.appellantType}
          poaAlert={args.ui.poaAlert}
          powerOfAttorney={powerOfAttorney}
          appealId={appealId}
        />
      </MemoryRouter>
    </Provider>
  );
};

const generateStore = (hasPOA, appellantType) => {
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
        powerOfAttorney
      },
      featureToggles: {
        poa_button_refresh: true
      }
    },
    editPOAInformation: true
  };
};

export const VeteranClaimantWithPOA = Template.bind({});
VeteranClaimantWithPOA.args = generateStore(true, APPELLANT_TYPES.VETERAN_CLAIMANT);

export const HealthcareProviderClaimantWithPOA = Template.bind({});
HealthcareProviderClaimantWithPOA.args = generateStore(true, APPELLANT_TYPES.HEALTHCARE_PROVIDER_CLAIMANT);

export const OtherClaimantWithPOA = Template.bind({});
OtherClaimantWithPOA.args = generateStore(true, APPELLANT_TYPES.OTHER_CLAIMANT);
