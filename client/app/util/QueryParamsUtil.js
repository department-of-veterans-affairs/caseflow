// Copied and slightly edited from https://gist.github.com/cvan/38fa77f1f28d3eb9d9c461e1d0d0d7d7

export const getQueryParams = (urlSearch) => urlSearch.substr(1).split('&').
  reduce((queryParamsOutput, params) => {
    const keyValue = params.split('=');
    const key = keyValue[0];
    const value = keyValue[1];

    if (key) {
      return (queryParamsOutput[key] = value, queryParamsOutput);
    }

    return queryParamsOutput;
  }, {});
