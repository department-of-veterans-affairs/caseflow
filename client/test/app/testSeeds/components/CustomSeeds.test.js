import React from 'react';
import { render, fireEvent, screen, container } from '@testing-library/react';
import CustomSeeds from 'app/testSeeds/components/CustomSeeds';
import CUSTOM_SEEDS from '../../../../constants/CUSTOM_SEEDS';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/testSeeds/reducers/root';
import { addCustomSeed } from 'app/testSeeds/reducers/seeds/seedsActions';
import thunk from 'redux-thunk';
import { mount } from 'enzyme';

describe('Custom Seeds', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk)
  );

  afterEach(() => {
    jest.clearAllMocks();
  });

  const seedTypes = Object.keys(CUSTOM_SEEDS);

  it('renders Custom Seeds correctly and check the buttons within the page', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        <CustomSeeds />
      </Provider>
    );
    expect(screen.getByText('Download Appeals Ready to Distribute CSV')).toBeInTheDocument();
    expect(screen.getByText('Upload Test Cases CSV')).toBeInTheDocument();
    expect(screen.getByText('Download Template')).toBeInTheDocument();
    expect(screen.getByText('Reset all appeals')).toBeInTheDocument();
    expect(screen.getByText('reset form')).toBeInTheDocument();
  });

  it('should render input fields and buttons for each seed type', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        <CustomSeeds />
      </Provider>
    );

    // Check if input fields and buttons are rendered for each seed type
    seedTypes.forEach((type,index) => {
      const caseCountInput = screen.getByLabelText(`seed-count-${type}`);
      const daysAgoInput = screen.getByLabelText(`days-ago-${type}`);
      const cssIdInput = screen.getByLabelText(`css-id-${type}`);
      const button = screen.getAllByRole('button')[index];

      expect(caseCountInput).toBeInTheDocument();
      expect(daysAgoInput).toBeInTheDocument();
      expect(cssIdInput).toBeInTheDocument();
      expect(button).toBeInTheDocument();
    });
  });

  it('should update state when input values change', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        <CustomSeeds />
      </Provider>
    );
    const first_seed = seedTypes[0];
    const caseCountInput = screen.getByLabelText(`seed-count-${first_seed}`);
    const daysAgoInput = screen.getByLabelText(`days-ago-${first_seed}`);
    const cssIdInput = screen.getByLabelText(`css-id-${first_seed}`);

    fireEvent.change(caseCountInput, { target: { value: '10' } });
    fireEvent.change(daysAgoInput, { target: { value: '5' } });
    fireEvent.change(cssIdInput, { target: { value: '12345' } });

    expect(caseCountInput.value).toBe('10');
    expect(daysAgoInput.value).toBe('5');
    expect(cssIdInput.value).toBe('12345');
  });
});
