export const mapDataToInitialUi = (props = {}) => (
  {
    // eslint-disable-next-line camelcase
    unreadMessages: props.serverIntake?.unread_messages,
    userIsVhaEmployee: props.userIsVhaEmployee
  }
);

export const uiReducer = (state = mapDataToInitialUi(), action) => {
  switch (action.type) {
  default:
    return state;
  }
};
