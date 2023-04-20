import { useEffect, useState } from 'react';

// TODO: Move this hook to a new file and renamed it useLocalStorageFilter or something
const useLocalFilterStorage = (key, defaultValue) => {
  const [value, setValue] = useState(() => {
    const storedValue = localStorage.getItem(key);

    return storedValue && storedValue !== 'null' ? [storedValue] : defaultValue;
  });

  useEffect(() => {
    localStorage.setItem(key, value);
  }, [key, value]);

  return [value, setValue];
};

export default useLocalFilterStorage;
