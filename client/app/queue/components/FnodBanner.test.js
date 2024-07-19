import React from 'react';
import FnodBanner from 'app/queue/components/FnodBanner';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/queue/reducers';
import { render, screen } from '@testing-library/react';
import { formatDateStr } from 'app/util/DateUtil';

const convertRegex = (str) => {
  return new RegExp(str, 'i');
}

describe('FnodBanner', () => {
  const defaultAppeal = {
    id: '1234',
    veteran_appellant_deceased: true,
    veteranDateOfDeath: '2019-03-17',
    veteranFullName: 'Jane Doe'
  };

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupFnodBanner = (store) => {
    return render(
      <Provider store={store}>
        <FnodBanner
          appeal={defaultAppeal}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const { asFragment } = setupFnodBanner(store);

    expect(asFragment()).toMatchSnapshot();
  });

  it('displays date of death', () => {
    const store = getStore();
    const {container} = setupFnodBanner(store);

    const date = formatDateStr(defaultAppeal.veteranDateOfDeath);

    expect(container.querySelector('.usa-alert-text')).toBeInTheDocument();
    expect(screen.getByText(convertRegex(date))).toBeInTheDocument();
  });

  it('displays Veteran appellant\'s full name', () => {
    const store = getStore();
    const {container} = setupFnodBanner(store);

    const name = defaultAppeal.veteranFullName;

    expect(container.querySelector('.usa-alert-text')).toBeInTheDocument();
    expect(screen.getByText(convertRegex(name))).toBeInTheDocument();
  });
});
