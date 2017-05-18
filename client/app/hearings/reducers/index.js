/*
* This global reducer is called every time a state change is
* made in the application using `.dispatch`. The state changes implemented here
* are very simple. As they get more complicated and numerous,
* these are conventionally broken out into separate "actions" files
* that would live at client/app/actions/**.js.
*/

// TODO: is this meant to be something like a schema?
// it's too similar to the object in "mapDataToInitialState".
const initialState = {};

export const hearingsReducers = function(state = initialState, action = {}) {
  // for now there are specific actions so to keep lint happy...
  action.nothing = null;

  return state;
};
export default hearingsReducers;

export const mapDataToInitialState = function(state) {
  return {
    dockets: state.dockets
  };
};
