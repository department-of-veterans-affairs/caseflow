// Import your actual component and dependencies
import React from 'react';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, useHistory, Router } from 'react-router-dom';
import { createMemoryHistory } from 'history';
import ApiUtil from '../../../../app/util/ApiUtil';
import CorrespondenceReviewPackage
  from '../../../../app/queue/correspondence/review_package/CorrespondenceReviewPackage';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';

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

const store = createStore(rootReducer, applyMiddleware(thunk));

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

    expect(screen.queryByText('Cancel review of mail package')).not.toBeInTheDocument();

    fireEvent.click(screen.getByText('Cancel'));

    expect(screen.queryByText('Cancel review of mail package')).toBeInTheDocument();
    const closeButton = screen.getByRole('button', { name: 'Close' });

    expect(closeButton).toBeInTheDocument();

    fireEvent.click(closeButton);
    expect(screen.queryByText('Cancel review of mail package')).not.toBeInTheDocument();

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

    expect(screen.queryByText('Cancel review of mail package')).not.toBeInTheDocument();

    fireEvent.click(screen.getByText('Cancel'));

    expect(screen.queryByText('Cancel review of mail package')).toBeInTheDocument();
    const closeButton = screen.getByRole('button', { name: 'Close' });
    const cancelReviewButton = screen.getByRole('button', { name: 'Cancel review' });

    expect(closeButton).toBeInTheDocument();
    expect(cancelReviewButton).toBeInTheDocument();

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

    expect(screen.queryByText('Cancel review of mail package')).not.toBeInTheDocument();

    fireEvent.click(screen.getByText('Cancel'));

    expect(screen.queryByText('Cancel review of mail package')).toBeInTheDocument();
    const cancelReviewButton = screen.getByRole('button', { name: 'Cancel review' });

    expect(cancelReviewButton).toBeInTheDocument();

    fireEvent.click(cancelReviewButton);

    await waitFor(() => {
      expect(history.location.pathname).toBe('/queue/correspondence');
    });
  });

});

