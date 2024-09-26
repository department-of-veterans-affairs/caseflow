import { useEffect, useState } from 'react';

const usePageVisibility = (ref) => {
  const [isIntersecting, setIntersecting] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(([entry]) =>
      setIntersecting(entry.isIntersecting), { threshold: 0.8 }
    );

    observer.observe(ref.current);

    return () => {
      observer.disconnect();
    };
  }, [ref]);

  return isIntersecting;
};

export default usePageVisibility;
