import React from 'react';
import { axe } from 'jest-axe';
import { Provider } from 'react-redux';

import { render, screen } from '@testing-library/react';
import { MemoryRouter as Router } from 'react-router-dom';

import SavedSearches from 'app/nonComp/pages/SavedSearches';
import createNonCompStore from 'test/app/nonComp/nonCompStoreCreator';

describe('SavedSearches', () => {

  const setup = (storeValues = {}) => {
    const store = createNonCompStore(storeValues);

    return render(
      <Provider store={store}>
        <Router>
          <SavedSearches />
        </Router>
      </Provider>
    );
  };

  const SearchPageDescription =
    'Select a search you previously saved or look for ones others have saved by switching between the tabs.';

  const checkTableHeaders = () => {
    const expectedHeaders = ['', 'Search Name', 'Saved Date', 'Admin', 'Description'];

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
      const { container } = setup({ nonComp: { businessLineUrl: 'vha' } });

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('renders correctly', () => {
      const { container } = setup({ nonComp: { businessLineUrl: 'vha' } });

      expect(container).toMatchSnapshot();
    });

    it('renders Search page description', () => {
      setup({ nonComp: { businessLineUrl: 'vha' } });
      expect(screen.getAllByText(SearchPageDescription)).
        toBeTruthy();
    });

    it('renders a tab titled "My saved searches"', () => {
      setup({ nonComp: { businessLineUrl: 'vha' } });
      expect(screen.getAllByText('My saved searches')).toBeTruthy();

      checkTableHeaders();
      checkSortableHeaders();
    });

    it('renders a tab titled "All saved searches"', () => {
      setup({ nonComp: { businessLineUrl: 'vha' } });
      expect(screen.getAllByText('All saved searches')).toBeTruthy();

      checkTableHeaders();
      checkSortableHeaders();
    });
  });

  describe('Alert message', () => {
    it('should display a successful Alert banner', async() => {
      setup(
        {
          nonComp: { businessLineUrl: 'vha' },
          savedSearch: {
            message: 'You have successfully deleted First Search',
            status: 'succeeded',
            fetchedSearches: {
              userSearches: {},
              allSearches: {}

            }
          }
        });

      expect(screen.getByText('You have successfully deleted First Search')).toBeTruthy();
    });
  });
});
