import request from 'superagent';

export const downloadWithProgress = (url, options = {}) => {
  return new Promise((resolve, reject) => {
    request
      .get(url)
      .responseType('arraybuffer')
      .on('progress', (event) => {
        if (event.direction === 'download' && options.onProgress) {
          console.log(event);
          // const totalSize = event.currentTarget.response.byteLength;
          const totalSize = 198180; // hardcoded size of file for now, using doc10 for testing
          const percent = Math.round((event.loaded / totalSize) * 100);
          options.onProgress(percent);
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


