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

export const newState = (action, state) => {
  return Object.assign({}, state, {
    [action.payload.prop]: action.payload.value,
    save: Object.assign({}, state.save, {
      [action.payload.prop]: action.payload.value
    })
  });
};

export const hearingsReducers = function(state = mapDataToInitialState(), action = {}) {
  switch (action.type) {
  case 'POPULATE_DOCKETS':
    return Object.assign({}, state, {
      dockets: action.payload.dockets
    });

  case 'UPDATE_DAILY_DOCKET_NOTES':
  case 'UPDATE_DAILY_DOCKET_TRANSCRIPT':
  case 'UPDATE_DAILY_DOCKET_ACTION':
    return newState(action, state);

  case 'POPULATE_WORKSHEET':
    return Object.assign({}, state, {
      worksheet: action.payload.worksheet
    });

  case 'TOGGLE_SAVING':
    return Object.assign({}, state, {
      saving: !state.saving
    });

  case 'HANDLE_SERVER_ERROR':
    return Object.assign({}, state, {
      serverError: action.payload.err
    });

  default: return state;
  }
};
export default hearingsReducers;
