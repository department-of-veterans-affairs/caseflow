import React from 'react';
// import { axe } from 'jest-axe';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import { applyMiddleware, createStore, compose } from 'redux';
import userEvent from '@testing-library/user-event';
import { render, screen } from '@testing-library/react';
import selectEvent from 'react-select-event';

import ReportPage from 'app/nonComp/pages/ReportPage';
import ApiUtil from '../../../app/util/ApiUtil';

const createReducer = (storeValues) => {
  return (state = storeValues) => {

    return state;
  };
};

const createStoreValues = () => {
  return {
    orgUsers: {
      users: [
        {
          css_id: 'VHAUSER01',
          full_name: 'VHAUSER01',
          id: '01',
          type: 'user',
        },
        {
          css_id: 'VHAUSER02',
          full_name: 'VHAUSER02',
          id: '02',
          type: 'user',
        },
        {
          css_id: 'VHAUSER03',
          full_name: 'VHAUSER03',
          id: '03',
          type: 'user',
        }
      ]
    }
  };
};

const getUsers = () => {
  ApiUtil.get = jest.fn().mockResolvedValue({
    data: [
      {
        id: '20',
        type: 'user',
        attributes: {
          css_id: 'VHAADMIN',
          full_name: 'VHAADMIN',
          email: null
        }
      },
      {
        id: '21',
        type: 'user',
        attributes: {
          css_id: 'VHAADMIN2',
          full_name: 'VHAADMIN2',
          email: null
        }
      },
      {
        id: '2000006012',
        type: 'user',
        attributes: {
          css_id: 'ACBAUERVVHAH',
          full_name: 'Susanna Bahringer DDS',
          email: 'marilou_doyle@hahn.org'
        }
      },
    ]
  });
};

beforeEach(() => {
  getUsers();
});

describe('Personnel', () => {
  const setup = (storeValues) => {
    const reducer = createReducer(storeValues);

    const store = createStore(
      reducer,
      compose(applyMiddleware(thunk))
    );

    return render(
      <Provider store={store}>
        <ReportPage />
      </Provider>
    );
  };

  const selectPlaceholder = 'Select...';

  const navigateToPersonnel = async () => {
    const addConditionBtn = screen.getByText('Add Condition');

    await userEvent.click(addConditionBtn);

    const selectText = screen.getByText('Select a variable');

    await selectEvent.select(selectText, ['Personnel']);
  };

  it('renders a dropdown with the correct label', async () => {
    const storeValues = createStoreValues();

    setup(storeValues);
    await navigateToPersonnel();

    expect(screen.getByText('VHA team members')).toBeInTheDocument();
    expect(screen.getAllByText(selectPlaceholder).length).toBe(2);
  });

  it('allows to select multiple options from dropdown', async () => {
    const storeValues = createStoreValues();

    setup(storeValues);
    await navigateToPersonnel();

    let selectText = screen.getAllByText(selectPlaceholder);
    const teamMember1 = 'VHAUSER01';

    await selectEvent.select(selectText[1], [teamMember1]);

    selectText = screen.getByText(teamMember1);
    const teamMember2 = 'VHAUSER02';

    await selectEvent.select(selectText, [teamMember2]);

    expect(screen.getByText(teamMember1)).toBeInTheDocument();
    expect(screen.getByText(teamMember2)).toBeInTheDocument();
  });
});
