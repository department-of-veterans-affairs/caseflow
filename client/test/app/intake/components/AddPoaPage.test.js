import React from 'react';
import faker from 'faker';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router';
import { createStore } from 'redux';
import { screen, render, waitFor, fireEvent } from '@testing-library/react';
import { createMemoryHistory } from 'history';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import PropTypes from 'prop-types';

import { AddPoaPage } from 'app/intake/addPOA/AddPoaPage';
import { renderIntakePage } from '../testUtils';
import { reducer, generateInitialState } from 'app/intake/index';
import { PAGE_PATHS } from 'app/intake/constants';

const HLRIntakeProviders = ({ children }) => {
  const hlrState = generateInitialState();

  hlrState.intake.formType = 'higher_level_review';
  const store = createStore(reducer, { ...hlrState });

  return (
    <Provider store={store}>
      <MemoryRouter>{children}</MemoryRouter>
    </Provider>
  );
};

HLRIntakeProviders.propTypes = {
  children: PropTypes.node
};

describe('AddPoaPage', () => {
  const onSubmit = jest.fn();
  const onBack = jest.fn();

  const fixedAddress = {
    address_line_1: '9999 MISSION ST',
    address_line_2: 'UBER',
    address_line_3: 'APT 2',
    city: 'SAN FRANCISCO',
    zip: '94103',
    country: 'USA',
    state: 'CA'
  };

  const fixedData = [{ name: 'John Attorney', participant_id: 334324234, address: fixedAddress }];

  const generatedData = Array.from({ length: 250 }, () => ({
    name: faker.name.findName(),
    participant_id: faker.random.number(),
    address: null
  }));

  const fullData = fixedData.concat(generatedData);

  // Simple string search for mocking
  const fetchFn = async (search = '') => {
    const regex = RegExp(search, 'i');

    return fullData.filter((item) => regex.test(item.name));
  };

  const asyncFn = async (search = '') => {
    return await fetchFn(search);
  };

  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers('modern');
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  // Thee problem is that asyncFn is not being passed search params maybe?
  const defaults = { onSubmit, onBack, onAttorneySearch: asyncFn };
  const setup = (
    storeValues,
    history = createMemoryHistory({ initialEntries: [PAGE_PATHS.ADD_POWER_OF_ATTORNEY] }),
  ) => {
    const page = <AddPoaPage {...defaults} />;

    return renderIntakePage(page, storeValues, history);
  };

  const setupHLR = () => {
    return render(<AddPoaPage {...defaults} />, { wrapper: HLRIntakeProviders });
  };

  it('renders default state correctly', async () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
    await waitFor(() => {
      expect(
        screen.getByText("Add Claimant's POA")
      ).toBeInTheDocument();
    });
  });

  it('fires onBack', async () => {
    setup();

    const backButton = screen.getByRole('button', { name: /back/i });

    expect(onBack).not.toHaveBeenCalled();

    await waitFor(() => {
      userEvent.click(backButton);
      expect(onBack).not.toHaveBeenCalled();
    });
  });

  it('Can select Name not listed and it renders individual and organization forms correct', async () => {
    const { container } = setup();
    const label = "Representative's name";
    const attorneySelect = screen.getByLabelText(label);

    // Fill in the select with a name that matches the dummy data
    fireEvent.change(attorneySelect, { target: { value: 'John' } });

    await selectEvent.select(
      attorneySelect,
      ['Name not listed']
    );

    // Set type to individual
    await userEvent.click(
      screen.getByRole('radio', { name: /individual/i })
    );

    await waitFor(() => {
      expect(
        screen.getByLabelText('First name')
      ).toBeInTheDocument();
    });

    expect(container).toMatchSnapshot();

    // set type to organization
    await userEvent.click(
      screen.getByRole('radio', { name: /organization/i })
    );

    await waitFor(() => {
      expect(
        screen.getByLabelText('Organization name')
      ).toBeInTheDocument();
    });

    expect(container).toMatchSnapshot();

  });

  it('Can select an existing attorney and it renders correctly', async () => {
    const { container } = setup();
    const label = "Representative's name";
    const attorneySelect = screen.getByLabelText(label);

    // Fill in the select with a name that matches the dummy data
    fireEvent.change(attorneySelect, { target: { value: 'John' } });

    await selectEvent.select(
      attorneySelect,
      ['John Attorney']
    );

    await waitFor(() => {
      expect(screen.getByText('John Attorney')).toBeInTheDocument();
      expect(screen.getByText(new RegExp(fixedAddress.address_line_1, 'i'))).toBeInTheDocument();
    });

    expect(container).toMatchSnapshot();
  });

  it('Can select Name not listed and it renders individual and organization forms correct for HLR/SC', async () => {
    const { container } = setupHLR();

    const label = "Representative's name";
    const attorneySelect = screen.getByLabelText(label);
    const buttonText = 'Continue to next step';

    // Fill in the select with a name that matches the dummy data
    fireEvent.change(attorneySelect, { target: { value: 'John' } });

    await selectEvent.select(
      attorneySelect,
      ['Name not listed']
    );

    // Set type to individual
    await userEvent.click(
      screen.getByRole('radio', { name: /individual/i })
    );

    await waitFor(() => {
      expect(
        screen.getByLabelText('First name')
      ).toBeInTheDocument();
    });

    expect(container).toMatchSnapshot();

    expect(screen.getByText(buttonText)).toBeDisabled();

    // Enter First Name
    await userEvent.type(
      screen.getByLabelText('First name'),
      'Harvey'
    );

    // Enter Last Name
    await userEvent.type(
      screen.getByLabelText('Last name'),
      'Attorney'
    );

    // Form should be able to be submitted after those two fields are entered
    await waitFor(() => {
      expect(screen.getByText(buttonText)).not.toBeDisabled();
    });

    // Set type to organization
    await userEvent.click(
      screen.getByRole('radio', { name: /organization/i })
    );

    expect(container).toMatchSnapshot();

  });

  describe('Redirection to Intake home page', () => {
    let storeValues;

    beforeEach(() => {
      storeValues = generateInitialState();
    });

    it('takes place whenever intake has been cancelled (formType === null)', async () => {
      storeValues.intake = {
        ...storeValues.intake,
        formType: null
      };

      const { history } = setup(storeValues);

      expect(await history.location.pathname).toBe(PAGE_PATHS.BEGIN);
    });

    it('does not take place is there is a formType, indicating no cancellation', async () => {
      storeValues.intake = {
        ...storeValues.intake,
        formType: 'appeal'
      };

      const { history } = setup(storeValues);

      expect(await history.location.pathname).toBe(PAGE_PATHS.ADD_POWER_OF_ATTORNEY);
    });
  });
});
