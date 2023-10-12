import React from 'react';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import '@testing-library/jest-dom';

import {
  genericTaskPageData, genericTaskPageDataWithVhaAdmin, inProgressTaskPageData, inProgressTaskPageDataWithAdmin
} from '../../../test/data/queue/nonCompTaskPage/nonCompTaskPageData';
import TaskPageUnconnected from 'app/nonComp/pages/TaskPage';
import ApiUtil from '../../../app/util/ApiUtil';

const basicVhaProps = {
 ...inProgressTaskPageData.serverNonComp
};
const basicVhaPropsWithAdmin = {
  ...inProgressTaskPageDataWithAdmin.serverNonComp
 };

const basicGenericProps = {
  ...genericTaskPageData.serverNonComp
};

const basicGenericPropsWithVhaAdminTrue = {
  ...genericTaskPageDataWithVhaAdmin.serverNonComp
};

beforeEach(() => {
  jest.clearAllMocks();

  // Mock ApiUtil get so the tasks will appear in the queues.
  ApiUtil.get = jest.fn().mockResolvedValue({
    tasks: { data: [inProgressTaskPageData] },
    tasks_per_page: 15,
    task_page_count: 3,
    total_task_count: 44
  });
});

const createReducer = (storeValues) => {
  return function (state = storeValues) {

    return state;
  };
};

const renderTaskPage = (props) => {

  const nonCompTabsReducer = createReducer(props);

  const store = createStore(nonCompTabsReducer);

  return render(
    <Provider store={store}>
      <TaskPageUnconnected />
    </Provider>
  );
};

afterEach(() => {
  jest.clearAllMocks();
});

describe('TaskPageVha', () => {
  it('renders a page with Edit Issue button disabled when vhaAdmin is false and businessLine is vha', () => {
    renderTaskPage(basicVhaProps);
    const submit = screen.getByRole('link', { name: /Edit Issues/i });
    expect(submit).toHaveClass('disabled');
  });

  it('renders active Edit Issue button when vhaAdmin is true and businessLine is not vha', async () => {
    renderTaskPage(basicVhaPropsWithAdmin);
    const submit = screen.getByRole('link', { name: /Edit Issues/i });
    expect(submit).not.toHaveClass('disabled');
  });
});

describe('TaskPageGeneric', () => {
  it('renders active Edit Issue button when vhaAdmin is false and businessLine is not vha', async () => {
    renderTaskPage(basicGenericProps);
    const submit = screen.getByRole('link', { name: /Edit Issues/i });
    expect(submit).not.toHaveClass('disabled');
  });

  it('renders active Edit Issue button when vhaAdmin is true and businessLine is not vha', async () => {
    renderTaskPage(basicGenericPropsWithVhaAdminTrue);
    const submit = screen.getByRole('link', { name: /Edit Issues/i });
    expect(submit).not.toHaveClass('disabled');
  });
});
