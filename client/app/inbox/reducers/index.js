export const mapDataToInitialState = (props = {}) => ({ ...props.inbox });

export const inboxReducer = (state = mapDataToInitialState(), action) => {
  switch (action.type) {
  default:
    return state;
  }
};
