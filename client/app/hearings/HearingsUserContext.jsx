import React from 'react';

// Provides the active user of the hearings application.
// The user it provides should be immutable.
export const HearingsUserContext = React.createContext(Object.freeze({}));
