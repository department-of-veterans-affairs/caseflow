// Import your actual component and dependencies
import React from 'react';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, useHistory, Router } from 'react-router-dom';
import { createMemoryHistory } from 'history';
import ApiUtil from '../../../../app/util/ApiUtil';
import CorrespondenceReviewPackage
  from '../../../../app/queue/correspondence/ReviewPackage/CorrespondenceReviewPackage';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';
import {
  correspondenceData,
  correspondenceDocumentsData,
  packageDocumentTypeData,
  correspondenceTypes
} from 'test/data/correspondence';

jest.mock('redux', () => ({
  ...jest.requireActual('redux'),
  bindActionCreators: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
}));

const createSpyGet = () => {
  return jest.spyOn(ApiUtil, 'get').mockImplementation(
    () =>
      new Promise((resolve) =>
        resolve({
          body: { general_information: {}, correspondence_documents: [] },
        })
      )
  );
};

let initialState = {
  reviewPackage: {
    correspondence: correspondenceData,
    packageDocumentType: packageDocumentTypeData,
    correspondenceDocuments: correspondenceDocumentsData,
    correspondenceTypes,
    correspondenceTypeId: 1
  }
};

const store = createStore(rootReducer, initialState, applyMiddleware(thunk));

const LocationDisplay = () => {
  const history = useHistory();

  return <div data-testid="location-display">{history.location.pathname}</div>;
};

describe('CorrespondenceReviewPackage', () => {
  let props;

  beforeEach(() => {
    createSpyGet();

    props = {
      correspondenceId: '123',
      correspondenceData,
      correspondenceTypes,
      correspondenceTypeId: 1

    };
  });

  test('render modal', async () => {
    render(
      <Provider store={store}>
        <MemoryRouter>
          <CorrespondenceReviewPackage {...props} />
        </MemoryRouter>
      </Provider>
    );

    expect(screen.queryByText('All unsaved changes made to this mail package will be lost')).not.toBeInTheDocument();

    const button = screen.getByRole('button', { name: 'Return to queue' });

    expect(screen.queryByRole('heading', { name: 'Return to queue' })).not.toBeInTheDocument();
    fireEvent.click(button);

    if (props.disableButton) {
      expect(screen.queryByRole('heading', { name: 'Return to queue' })).toBeInTheDocument();
      expect(screen.getByText(/All unsaved changes made to this mail package will be lost/)).toBeInTheDocument();
      const closeButton = screen.getByRole('button', { name: 'Close' });

      expect(closeButton).toBeInTheDocument();
      fireEvent.click(closeButton);
      expect(screen.queryByText('All unsaved changes made to this mail package will be lost')).not.toBeInTheDocument();
    }

  });

  test('renders modal with correct title, buttons, and text', async () => {
    render(
      <Provider store={store}>
        <MemoryRouter>
          <Route >
            <CorrespondenceReviewPackage {...props} />
          </Route>
        </MemoryRouter>
      </Provider>
    );

    expect(screen.queryByText('All unsaved changes made to this mail package will be lost')).not.toBeInTheDocument();
    fireEvent.click(screen.getByText('Return to queue'));

    if (props.disableButton) {
      expect(screen.getByText(/All unsaved changes made to this mail package will be lost/)).toBeInTheDocument();
      const closeButton = screen.getByRole('button', { name: 'Close' });
      const cancelReviewButton = screen.getByRole('button', { name: 'Confirm' });

      expect(closeButton).toBeInTheDocument();
      expect(cancelReviewButton).toBeInTheDocument();
    }
  });

  test('redirect page when Cancel review is clicked', async () => {
    const history = createMemoryHistory({ initialEntries: ['/queue/correspondence'] });

    render(
      <Provider store={store}>
        <Router history={history}>
          <Route path="/queue/correspondence">
            <CorrespondenceReviewPackage {...props} />
            <LocationDisplay />
          </Route>
        </Router>
      </Provider>
    );

    expect(screen.queryByText('All unsaved changes made to this mail package will be lost')).not.toBeInTheDocument();
    fireEvent.click(screen.getByText('Return to queue'));

    if (props.disableButton) {
      expect(screen.getByText(/All unsaved changes made to this mail package will be lost/)).toBeInTheDocument();
      const cancelReviewButton = screen.getByRole('button', { name: 'Confirm' });

      expect(cancelReviewButton).toBeInTheDocument();
      fireEvent.click(cancelReviewButton);

      await waitFor(() => {
        expect(history.location.pathname).toBe('/queue/correspondence');
      });
    }
  });
});

