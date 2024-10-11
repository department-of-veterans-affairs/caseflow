import React from 'react';
import { axe } from 'jest-axe';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import { applyMiddleware, createStore, compose } from 'redux';

import userEvent from '@testing-library/user-event';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { createMemoryHistory } from 'history';
// import savedSearch from 'app/nonComp/pages/ReportPage';
import SavedSearchPage from 'app/nonComp/pages/SavedSearchPage';
import selectEvent from 'react-select-event';

import CombinedNonCompReducer from 'app/nonComp/reducers';

import REPORT_TYPE_CONSTANTS from 'constants/REPORT_TYPE_CONSTANTS';

describe('SavedSearchPage', () => {
  const setup = (storeValues = {}) => {
    const store = createStore(
      CombinedNonCompReducer,
      storeValues,
      compose(applyMiddleware(thunk))
    );

    return render(
      <Provider store={store}>
        <SavedSearchPage />
      </Provider>
    );
  };

  const SearchPageDescription =
    'Select a search you previously saved or look for ones others have saved by switching between tabs.';

  const checkTableHeaders = () => {
    const expectedHeaders = ['', 'Search Name', 'Saved Date', 'Admin', 'Search Description'];

    const columnHeaders = screen.getAllByRole('columnheader');

    expect(columnHeaders).toHaveLength(expectedHeaders.length);

    columnHeaders.forEach((header, index) => {

      const span = header.querySelector('span > span');

      expect(span.textContent).toBe(expectedHeaders[index]);
    });
  };

  const checkSortableHeaders = () => {
    const columnName = ['Search Name', 'Saved Date', 'Admin'];

    columnName.forEach((header) => {
      expect(screen.getByLabelText(`Sort by ${header}`)).toBeInTheDocument();
    });
  };

  describe('renders correctly', () => {
    it('passes a11y testing', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    it('renders Search page description', () => {
      setup();
      expect(screen.getAllByText(SearchPageDescription)).
        toBeTruthy();
    });

    it('renders a tab titled "My saved searches"', () => {
      setup();
      expect(screen.getAllByText('My saved searches')).toBeTruthy();

      checkTableHeaders();
      checkSortableHeaders();
    });

    it('renders a tab titled "All saved searches"', () => {
      setup();
      expect(screen.getAllByText('All saved searches')).toBeTruthy();

      checkTableHeaders();
      checkSortableHeaders();
    });
  });
});
