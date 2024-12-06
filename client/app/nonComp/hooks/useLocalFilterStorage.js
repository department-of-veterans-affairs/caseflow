import { compact } from 'lodash';
import { useEffect, useState } from 'react';

const useLocalFilterStorage = (key, defaultValue) => {
  const [value, setValue] = useState(() => {
    const storedValue = localStorage.getItem(key);

    if (storedValue === null) {
      return defaultValue;
    }

    const regex = /col=[^&]+&val=[^,]+(?:,[^&,]+)*(?=,|$)/g;
    const columnsWithValues = [...storedValue.matchAll(regex)].map((match) => match[0]);

    return compact(columnsWithValues);
  });

  useEffect(() => {
    localStorage.setItem(key, value);
  }, [key, value]);

  return [value, setValue];
};

export default useLocalFilterStorage;
