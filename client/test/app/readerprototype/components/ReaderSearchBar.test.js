import { render, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { def, get } from 'bdd-lazy-var/getter';
import React, { useState } from 'react';
import { Provider } from 'react-redux';
import RenderSearchBar from '../../../../app/readerprototype/components/ReaderSearchBar';
import { defaultStore } from '../helpers';

jest.mock('lodash/debounce', () => ({
  ...jest.requireActual('lodash/debounce'),
  __esModule: true,
  default: (func) => func,
}));

afterEach(() => jest.clearAllMocks());

describe('finds results', () => {
  def('store', () => defaultStore(
    {
      searchActionReducer: {
        matchIndex: 0,
        indexToHighlight: null,
        relativeIndex: 0,
        pageIndexWithMatch: null,
        extractedText: {
          'someFile-0': {
            id: 'someFile-0',
            file: 'someFile',
            pageIndex: 0,
            text: 'Voluptate z fugiat sunt deserunt voluptate ipsum nulla reprehenderit id est nulla consequat.'
          },
          'someFile-1': {
            id: 'someFile-1',
            file: 'someFile',
            pageIndex: 1,
            text: 'Sintz z proident ad adipisicing.'
          },
          'someFile-2': {
            id: 'someFile-2',
            file: 'someFile',
            pageIndex: 2,
            text: 'Dolor minim zanim eu aliqua consectetur non proident fugiat proident dolore reprehenderit qui.'
          },
        }
      }
    }
  ));
  const DummyComponent = () => {
    const [openSearch, setOpenSearch] = useState(false);

    return (
      <Provider store={get.store}>
        <button onClick={() => setOpenSearch(true)}>Open</button>
        {openSearch && <RenderSearchBar file="someFile" />}

        <div id="pdfContainer" />
      </Provider>
    );
  };

  it('finds text', async () => {
    const { getByPlaceholderText, getByText, getByDisplayValue } = render(<DummyComponent />);

    userEvent.click(getByText('Open'));
    await waitFor(() => getByPlaceholderText('Type to search...'));
    await waitFor(() => expect(getByDisplayValue('0 of 0')).toBeInTheDocument());
    const input = getByPlaceholderText('Type to search...');

    await waitFor(() => userEvent.type(input, 'z'));
    await waitFor(() => expect(getByDisplayValue('1 of 4')).toBeInTheDocument());

    userEvent.click(getByText('Previous Match'));
    await waitFor(() => expect(getByDisplayValue('4 of 4')).toBeInTheDocument());

    userEvent.click(getByText('Next Match'));
    await waitFor(() => expect(getByDisplayValue('1 of 4')).toBeInTheDocument());
  });
});
