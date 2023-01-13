export const initialState = {
  messages: {
    success: null,
    error: null
  },
  featureToggles: {},
  userRole: '',
  userCssId: '',
  userInfo: null,
  organizations: [],
  activeOrganization: {
    id: null,
    name: null,
    isVso: false
  },
  userIsVsoEmployee: false,
  userIsCamoEmployee: false,
  feedbackUrl: '#',
  loadedUserId: null,
};


