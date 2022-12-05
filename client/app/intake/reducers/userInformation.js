import { update } from '../../util/ReducerUtil';

const updateFromServerUserInformation = (state, userInformation) => {
  return update(state, {
    userDisplayName: {
      $set: userInformation.userDisplayName
    },
    userCanIntakeAppeals: {
      $set: Boolean(userInformation.userCanIntakeAppeals)
    },
    userIsVhaEmployee: {
      $set: Boolean(userInformation.userIsVhaEmployee)
    },
    unreadMessages: {
      $set: Boolean(userInformation.unreadMessages)
    },
  });
};

export const mapDataToUserInformation = (data = { userInformation: {} }) =>
  updateFromServerUserInformation(
    {
      userDisplayName: null,
      userCanIntakeAppeals: false,
      userIsVhaEmployee: false,
      unreadMessages: false
    },
    data.userInformation
  );

export const userInformationReducer = (state = mapDataToUserInformation()) => {
  return state;
};
