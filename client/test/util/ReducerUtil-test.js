import { expect } from 'chai';
import ReducerUtil from '../../app/util/ReducerUtil';

describe('ReducerUtil', () => {
  context('.changeFieldValue', () => {
    let action, currentState, newState;

    beforeEach(() => {
      currentState = {
        firstField: false,
        secondField: null
      };
      action = {
        payload: {
          field: 'secondField',
          value: '123'
        }
      };
      newState = ReducerUtil.changeFieldValue(currentState, action);
    });

    it('updates correct field', () => {
      expect(newState.secondField).to.equal('123');
    });
    it('does not change other fields', () => {
      expect(newState.firstField).to.equal(currentState.firstField);
    });
  });
});
