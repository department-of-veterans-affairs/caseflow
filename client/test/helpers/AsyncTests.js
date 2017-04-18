if (!global._babelPolyfill) { // eslint-disable-line no-underscore-dangle
  require('babel-polyfill'); // eslint-disable-line global-require
}

export const asyncTest = (fn) => {
  return () => {
    return new Promise(async (resolve, reject) => {
      try {
        await fn();
        resolve();
      } catch (err) {
        reject(err);
      }
    });
  };
};

export const pause = (ms = 0) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      return resolve();
    }, ms);
  });
};
