import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import COPY from '../../../../COPY';
import IssueModificationList from 'app/intake/components/IssueModificationList';
import {
  additionProps,
  modificationProps,
  removalProps,
  withdrawalProps,
} from 'test/data/issueModificationListProps';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import {
  createQueueReducer
} from 'test/app/queue/components/modalUtils';

describe('IssueModificationList', () => {
  const adminStoreValues = { userIsVhaAdmin: true };
  const nonAdminStoreValues = { userIsVhaAdmin: false };
  const dropdownClass = '.cf-select__control';
  const menuClass = '.cf-select__menu';

  const setup = (storeValues, testProps) => {
    const queueReducer = createQueueReducer(storeValues);
    const store = createStore(
      queueReducer,
      compose(applyMiddleware(thunk))
    );

    render(
      <Provider store={store}>
        <IssueModificationList
          {...testProps}
        />
      </Provider>
    );
  };

  describe('renders section titles and action options for non admin users', () => {
    const storeValues = { ...nonAdminStoreValues };

    it('Addition request type', () => {
      setup(storeValues, additionProps);
      const dropdown = document.querySelector(dropdownClass);

      expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.SECTION_TITLE)).toBeInTheDocument();
      expect(dropdown).toBeInTheDocument();

      fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

      expect(document.querySelector(menuClass)).toBeInTheDocument();
      expect(screen.getByText('Edit addition request')).toBeInTheDocument();
      expect(screen.getByText('Cancel addition request')).toBeInTheDocument();
    });

    it('Modification request type', () => {
      setup(storeValues, modificationProps);
      const dropdown = document.querySelector(dropdownClass);

      expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.SECTION_TITLE)).toBeInTheDocument();
      expect(dropdown).toBeInTheDocument();

      fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

      expect(document.querySelector(menuClass)).toBeInTheDocument();
      expect(screen.getByText('Edit modification request')).toBeInTheDocument();
      expect(screen.getByText('Cancel modification request')).toBeInTheDocument();
    });

    it('Removal request type', () => {
      setup(storeValues, removalProps);
      const dropdown = document.querySelector(dropdownClass);

      expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.SECTION_TITLE)).toBeInTheDocument();
      expect(dropdown).toBeInTheDocument();

      fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

      expect(document.querySelector(menuClass)).toBeInTheDocument();
      expect(screen.getByText('Edit removal request')).toBeInTheDocument();
      expect(screen.getByText('Cancel removal request')).toBeInTheDocument();
    });

    it('Withdrawal request type', () => {
      setup(storeValues, withdrawalProps);
      const dropdown = document.querySelector(dropdownClass);

      expect(dropdown).toBeInTheDocument();

      fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

      expect(document.querySelector(menuClass)).toBeInTheDocument();
      expect(screen.getByText('Edit withdrawal request')).toBeInTheDocument();
      expect(screen.getByText('Cancel withdrawal request')).toBeInTheDocument();
    });
  });

  describe('renders dropdown options for admin user', () => {
    const storeValues = { ...adminStoreValues };

    it('Addition request type', () => {
      setup(storeValues, additionProps);
      const dropdown = document.querySelector(dropdownClass);

      expect(dropdown).toBeInTheDocument();

      fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

      expect(document.querySelector(menuClass)).toBeInTheDocument();
      expect(screen.getByText('Review issue addition request')).toBeInTheDocument();
    });

    it('Modification request type', () => {
      setup(storeValues, modificationProps);
      const dropdown = document.querySelector(dropdownClass);

      expect(dropdown).toBeInTheDocument();

      fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

      expect(document.querySelector(menuClass)).toBeInTheDocument();
      expect(screen.getByText('Review issue modification request')).toBeInTheDocument();
    });

    it('Removal request type', () => {
      setup(storeValues, removalProps);
      const dropdown = document.querySelector(dropdownClass);

      expect(dropdown).toBeInTheDocument();

      fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

      expect(document.querySelector(menuClass)).toBeInTheDocument();
      expect(screen.getByText('Review issue removal request')).toBeInTheDocument();
    });

    it('Withdrawal request type', () => {
      setup(storeValues, withdrawalProps);
      const dropdown = document.querySelector(dropdownClass);

      expect(dropdown).toBeInTheDocument();

      fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

      expect(document.querySelector(menuClass)).toBeInTheDocument();
      expect(screen.getByText('Review issue withdrawal request')).toBeInTheDocument();
    });
  });
});
