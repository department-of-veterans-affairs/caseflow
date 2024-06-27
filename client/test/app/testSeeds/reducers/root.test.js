import rootReducer from 'app/testSeeds/reducers/root';
import { timeFunction } from 'app/util/PerfDebug';
import * as redux from 'redux';
// Mocking the leversReducer module
jest.mock('app/testSeeds/reducers/seeds/seedsReducer', () => jest.fn());
// Mocking timeFunction
jest.mock('app/util/PerfDebug', () => ({
  timeFunction: jest.fn((reducer, timeLabelFn) => reducer),
}));

jest.spyOn(redux, 'combineReducers');

describe('rootReducer', () => {
  it('calls rootReducer and timeLabel function', () => {

    expect(timeFunction).toHaveBeenCalledWith(
      rootReducer,
      expect.any(Function)
    );
    // Extracting the timeLabel function passed to timeFunction
    const timeLabelFn = timeFunction.mock.calls[0][1];
    // Testing the behavior of timeLabelFn
    const mockState = {};
    const mockAction = { type: 'TEST_ACTION' };
    const timeLabel = timeLabelFn('testLabel', mockState, mockAction);

    expect(timeLabel).toEqual('Action TEST_ACTION reducer time: testLabel');
  });
});
