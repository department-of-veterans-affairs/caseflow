/*
* This global reducer is called every time a state change is
* made in the application using `.dispatch`. The state changes implemented here
* are very simple. As they get more complicated and numerous,
* these are conventionally broken out into separate "actions" files
* that would live at client/app/actions/**.js.
*/

export const mapDataToInitialState = function(state = {}) {
  return state;
};

export const hearingsReducers = function(state = mapDataToInitialState(), action = {}) {
  switch (action.type) {
  case 'DOCKETS_LOADED':
    return Object.assign({}, state, {
      docketsLoaded: true
    });
  case 'POPULATE_DOCKETS':
    return Object.assign({}, state, {
      dockets: action.payload.dockets
    });
  default: return state;
  }
};
export default hearingsReducers;
