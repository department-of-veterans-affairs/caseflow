import { useEffect, useState } from 'react';

const useLocalFilterStorage = (key, defaultValue) => {
  const [value, setValue] = useState(() => {
    const storedValue = localStorage.getItem(key);

    return storedValue && storedValue !== 'null' ? [storedValue?.split(',')].flat() : defaultValue;
  });

  useEffect(() => {
    localStorage.setItem(key, value);
  }, [key, value]);

  return [value, setValue];
};

export default useLocalFilterStorage;
