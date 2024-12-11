import React from 'react';
import { Provider } from 'react-redux';
import { axe } from 'jest-axe';
import { MemoryRouter as Router } from 'react-router-dom';
import DeleteModal from 'app/nonComp/components/DeleteModal';
import { render, screen } from '@testing-library/react';

import createNonCompStore from 'test/app/nonComp/nonCompStoreCreator';
import COPY from 'app/../COPY';

const search = {
  savedSearch: {
    selectedSearch: {
      createdAt: '2024-11-14T08:58:19.706-05:00',
      description: 'Ad explicabo earum. Corrupti excepturi reiciendis. Qui eaque dolorem.',
      id: '61',
      name: 'Search to be deleted',
      savedSearch: { },
      type: 'saved_search',
      user: {
      }
    }
  }
};

describe('DeleteModal', () => {
  const setup = (storeValues = {}) => {
    const store = createNonCompStore(storeValues);

    return render(
      <Provider store={store}>
        <Router>
          <DeleteModal />
        </Router>
      </Provider>
    );
  };

  describe('renders correctly', () => {
    it('snapshot test', () => {
      expect(setup()).toMatchSnapshot();
    });

    it('passes a11y', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

  });

  describe('Different elements of Modal', () => {
    beforeEach(() => {
      setup(search);
    });

    it('should display title and description of the modal', () => {
      expect(screen.getByText(COPY.DELETE_SEARCH_TITLE)).toBeTruthy();

      expect(screen.getByText(COPY.DELETE_SEARCH_DESCRIPTION)).toBeTruthy();
    });

    it('should have Delete and Cancel button', () => {
      const deleteButton = screen.getByText('Delete');

      const cancelButton = screen.getByText('Cancel');

      expect(deleteButton).toBeTruthy();
      expect(cancelButton).toBeTruthy();
    });

    it('should have the name of the save search to be deleted', () => {
      expect(screen.getByText('Search to be deleted')).toBeTruthy();
    });
  });

});
