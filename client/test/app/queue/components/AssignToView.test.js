import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import COPY from '../../../../COPY';
import {
  createQueueReducer,
  getAppealId,
  getTaskId,
  enterTextFieldOptions,
  enterModalRadioOptions,
  selectFromDropdown,
  clickSubmissionButton
} from './modalUtils';
import AssignToView from 'app/queue/AssignToView';

const renderAssignToView = (modalType, storeValues, taskType) => {
  const appealId = getAppealId(storeValues);
  const taskId = getTaskId(storeValues, taskType);

  const queueReducer = createQueueReducer(storeValues);
  const store = createStore(
    queueReducer,
    compose(applyMiddleware(thunk))
  );

  const path = `/queue/appeals/${appealId}/tasks/${taskId}/modal/${modalType}`;

  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <Route component={(props) => {
          return <AssignToView {...props.match.params} modalType={modalType} />;
        }} path={`/queue/appeals/:appealId/tasks/:taskId/modal/${modalType}`} />
      </MemoryRouter>
    </Provider>
  );
};

describe('Whenver the EMO assigns an appeal to a Regional Processing Office', () => {
  it('placeholder', () => {
    expect(true).toBe(true);
  });
});

describe('Whenever VHA CAMO assigns an appeal to a Program Office', () => {
  it('placeholder', () => {
    expect(true).toBe(true);
  });
});

describe('Whenever a VHA Program Office assigns an appeal to a VISN/Regional Office', () => {
  it('placeholder', () => {
    expect(true).toBe(true);
  });
});
