import ApiUtil from '../../util/ApiUtil';
import { ACTIONS } from './constants';
import { mapAppellantDataFromApi, mapAppellantDataToApi } from './utils';

export const updateAppellantInformation = (appellantFormData, appellantId) => (dispatch) => {
  console.log(appellantId)
  const appellantData = mapAppellantDataToApi(appellantFormData);

  ApiUtil.patch(`/unrecognized_appellants/${appellantId}`, appellantData).then((response) => {
    dispatch({
      type: ACTIONS.UPDATE_APPELLANT_INFORMATION,
      payload: mapAppellantDataFromApi(response.body)
    });
  }, (error) => {
    console.log(error)
  })
}