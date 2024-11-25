import React from 'react';
import { Provider } from 'react-redux';
import { axe } from 'jest-axe';
import { MemoryRouter as Router } from 'react-router-dom';
import SaveLimitReachModal from 'app/nonComp/components/ReportPage/SaveLimitReachedModal';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import COPY from 'app/../COPY';
import createNonCompStore from 'test/app/nonComp/nonCompStoreCreator';
import savedSearchesData from '../../../data/nonComp/savedSearchesData';

describe('SaveLimitReachModal', () => {
  const setup = (storeValues = {}) => {
    const store = createNonCompStore(storeValues);

    return render(
      <Provider store={store}>
        <Router>
          <SaveLimitReachModal />
        </Router>
      </Provider>
    );
  };

  describe('renders correctly', () => {
    it('passes a11y testing', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('renders correctly', () => {
      expect(setup()).toMatchSnapshot();
    });
  });

  describe('displays all elements of the modal', () => {
    beforeEach(() => {
      setup({ nonComp: { businessLineUrl: 'vha' }, savedSearch: savedSearchesData.savedSearches });
    });

    it('should display title and description of the modal', () => {

      expect(screen.getByText('Limit Reached')).toBeTruthy();

      expect(screen.getByText(COPY.SAVE_LIMIT_REACH_MESSAGE)).toBeTruthy();
    });

    it('render delete button which should be enabled after clicking radio button', async () => {
      const deleteBtn = screen.getByText('Delete');

      expect(deleteBtn).toBeDisabled();

      const radioButtons = screen.getAllByRole('radio');

      userEvent.click(radioButtons[0]);

      expect(radioButtons[0]).toBeChecked();
      expect(deleteBtn).not.toBeDisabled();
    });

    it('render view saved searches', async () => {
      const viewSavedSearchesBtn = screen.getByText('View saved searches');

      expect(viewSavedSearchesBtn).not.toBeDisabled();
    });

  });

});
