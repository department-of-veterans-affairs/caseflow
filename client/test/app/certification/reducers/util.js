import { mapDataToInitialState } from
  '../../../../app/certification/reducers/index';

export const getBlankInitialState = () => {
  return mapDataToInitialState({
    appeal: {},
    form8: {}
  });
};
