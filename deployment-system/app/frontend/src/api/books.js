// Books API built on top of http client
import { http } from '../services/httpClient';

export const booksApi = {
  list: () => http.get('/books'),
  create: (data) => http.post('/books', data),
  update: (id, data) => http.put(`/books/${id}`, data),
  remove: (id) => http.delete(`/books/${id}`),
};
