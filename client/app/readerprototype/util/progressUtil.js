import request from 'superagent';

export const downloadWithProgress = (url, options = {}) => {
  return new Promise((resolve, reject) => {
    request
      .get(url)
      .responseType('arraybuffer')
      .on('progress', (event) => {
        if (event.direction === 'download' && options.onProgress) {
          options.onProgress(event.percent);
        }
      })
      .end((err, res) => {
        if (err) {
          if (options.onFailure) {
            options.onFailure(err);
          }
          reject(err);
        } else {
          if (options.onSuccess) {
            options.onSuccess(res.body);
          }
          resolve(res.body);
        }
      });
  });
};


