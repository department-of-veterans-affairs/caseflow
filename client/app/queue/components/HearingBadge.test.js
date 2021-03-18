import React from 'react';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from '../../../app/queue/reducers';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { axe } from 'jest-axe';
import { render } from '@testing-library/react';

import HearingBadge from 'app/queue/components/HearingBadge';

describe('HearingBadge', () => {

    const defaultHearing = {
        heldBy: 'ExampleJudgeName',
        disposition: 'ExampleDispositionText',
        date: '2020-01-15',
        type: 'AMA'
    };

    const tooltipText = 'H';

    const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

    const getHearingBadge = (store, hearing) => render(
        <Provider store={store}>
          <HearingBadge hearing={defaultHearing} />
        </Provider>
    );
    
    it('renders correctly', () => {
        const store = getStore();
        const component = getHearingBadge(store, defaultHearing);
    
        expect(component).toMatchSnapshot();
      });

    it('displays if there are hearings', () => {
        const store = getStore();
        const component = getHearingBadge(store, defaultHearing);
    
        expect(component.queryByRole('tooltip')).toHaveTextContent(tooltipText);
    });

    it('doesn\'t show if there are no hearings', () => {
      const store = getStore();
      const component = getHearingBadge(store, undefined); // eslint-disable-line no-undefined

      expect(component.queryByRole('tooltip')).toBeNull;
    });

    it('passes a11y', async () => {
        const store = getStore();
        const { container } = getHearingBadge(store, defaultHearing);
    
        const results = await axe(container);
    
        expect(results).toHaveNoViolations();
      });
});
