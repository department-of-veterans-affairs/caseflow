import { ACTIONS } from './seedsActionTypes';
import ApiUtil from '../../../util/ApiUtil';


export const addCustomSeed = (seed) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.ADD_CUSTOM_SEED,
      payload: {
        seed
      }
    });
  };

export const removeCustomSeed = (seed) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.REMOVE_CUSTOM_SEED,
      payload: {
        seed
      }
    });
  };

export const saveCustomSeeds = (seeds) =>
  (dispatch) => {

    console.log('saveCustomSeeds');
    console.log(seeds);
    return ApiUtil.post('/seeds/run-demo', { data: seeds }).then(() => {
      console.log("saved custom seed");
    }).
      catch((err) => {
        console.warn(err);
      });
  };
