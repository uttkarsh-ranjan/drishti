import React, { createContext, useContext, useState, useEffect } from 'react';
import axios from 'axios';

interface AuthContextType {
  token: string | null;
  role: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType>({
  token: null,
  role: null,
  login: async () => {},
  logout: () => {},
});

export const useAuth = () => useContext(AuthContext);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [token, setToken] = useState<string | null>(() => {
    const t = localStorage.getItem('access_token');
    if (t) axios.defaults.headers.common['Authorization'] = `Bearer ${t}`;
    return t;
  });
  const [role, setRole] = useState<string | null>(() => localStorage.getItem('role'));

  useEffect(() => {
    if (token) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    } else {
      delete axios.defaults.headers.common['Authorization'];
    }
  }, [token]);

  const login = async (email: string, password: string) => {
    const apiBase = `http://${window.location.hostname}:5000`;
    const res = await axios.post(`${apiBase}/api/auth/login`, { email, password });
    const { access_token, role: userRole } = res.data;
    localStorage.setItem('access_token', access_token);
    localStorage.setItem('role', userRole);
    setToken(access_token);
    setRole(userRole);
    axios.defaults.headers.common['Authorization'] = `Bearer ${access_token}`;
  };

  const logout = () => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('role');
    setToken(null);
    setRole(null);
  };

  return <AuthContext.Provider value={{ token, role, login, logout }}>{children}</AuthContext.Provider>;
};
