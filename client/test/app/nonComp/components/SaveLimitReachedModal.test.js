import React from 'react';
import { Provider } from 'react-redux';
import { axe } from 'jest-axe';
import { MemoryRouter as Router } from 'react-router-dom';
import SaveLimitReachModal from 'app/nonComp/components/ReportPage/SaveLimitReachedModal';
import { render, screen } from '@testing-library/react';

import createNonCompStore from 'test/app/nonComp/nonCompStoreCreator';
import COPY from 'app/../COPY';

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
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });
  });

  describe('displays header and description properly', () => {
    it('should display title and description of the modal', () => {
      setup();

      expect(screen.getByText('Limit Reached')).toBeTruthy();

      expect(screen.getByText(COPY.SAVE_LIMIT_REACH_MESSAGE)).toBeTruthy();
    });
  });

});
