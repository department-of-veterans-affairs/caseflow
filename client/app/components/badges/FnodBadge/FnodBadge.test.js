import React from 'react';
import { render, screen } from '@testing-library/react';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

import rootReducer from 'app/queue/reducers';
import FnodBadge from './FnodBadge';
import { tooltipListStyling } from 'app/components/badges/style';
import { DateString } from 'app/util/DateUtil';
import COPY from 'COPY';

describe('FnodBadge', () => {

  const veteranAppellantDeceased = true;
  const uniqueId = '1234'
  const veteranDateOfDeath = '2019-03-17';
  const tooltipText = <div>
    <strong>Date of Death Reported</strong>
    <ul {...tooltipListStyling}>
      <li><strong>Source:</strong> {COPY.FNOD_SOURCE}</li>
      {veteranDateOfDeath &&
        <li><strong>Date of Death:</strong> <DateString date={veteranDateOfDeath} /></li>
      }
    </ul>
  </div>;

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupFnodBadge = (store) => {
    return (
      <Provider store={store}>
        <FnodBadge
          uniqueId={uniqueId}
          veteranAppellantDeceased={veteranAppellantDeceased}
          tooltipText={tooltipText}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const { asFragment } = render(setupFnodBadge(store));

    expect(screen.getByText('FNOD')).toBeInTheDocument();
    expect(screen.getByText('Date of Death Reported')).toBeInTheDocument()
    expect(screen.getByText('Source:')).toBeInTheDocument();
    expect(screen.getByText('Date of Death:')).toBeInTheDocument();
    expect(screen.getByText('03/17/19')).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });
});
