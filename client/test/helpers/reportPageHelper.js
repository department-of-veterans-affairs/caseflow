import ApiUtil from 'app/util/ApiUtil';

export const getVhaUsers = () => {
  const data = {
    users: {
      data: [
        {
          id: '01',
          type: 'user',
          attributes: {
            css_id: 'VHAUSER01',
            full_name: 'VHAUSER01',
            email: null
          }
        },
        {
          id: '02',
          type: 'user',
          attributes: {
            css_id: 'VHAUSER02',
            full_name: 'VHAUSER02',
            email: null
          }
        }
      ]
    }
  };

  ApiUtil.get = jest.fn().mockResolvedValue({ body: data });
};
