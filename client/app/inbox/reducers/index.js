export const mapDataToInitialState = function(props = {}) {
  const { inbox } = props;

  let state = inbox;

  return state;
};

export const inboxReducer = (state = mapDataToInitialState(), action) => {
  switch (action.type) {
  default:
    return state;
  }
};
