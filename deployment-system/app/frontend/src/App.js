import React, { useEffect, useState } from 'react';
import BookList from './BookList';
import BookForm from './BookForm';
import { booksApi } from './api/books';
import './styles.css';

export default function App() {
  const [books, setBooks] = useState([]);
  const [editing, setEditing] = useState(null);
  const [error, setError] = useState(null);

  const loadBooks = () =>
    booksApi
      .list()
      .then(setBooks)
      .catch((e) => setError(e.message));

  useEffect(() => {
    loadBooks();
  }, []);

  const handleCreate = (data) =>
    booksApi
      .create(data)
      .then(loadBooks)
      .catch((e) => setError(e.message));

  const handleUpdate = (id, data) =>
    booksApi
      .update(id, data)
      .then(() => {
        setEditing(null);
        return loadBooks();
      })
      .catch((e) => setError(e.message));

  const handleDelete = (id) =>
    booksApi
      .remove(id)
      .then(loadBooks)
      .catch((e) => setError(e.message));

  return (
    <div className="min-h-screen bg-gray-100 p-6">
      <div className="max-w-2xl mx-auto bg-white rounded-xl shadow-md p-6 space-y-6">
        <h1 className="text-3xl font-bold text-gray-800 text-center">📚 Book Manager</h1>

        {error && (
          <div className="rounded-md bg-red-50 p-3 text-red-700 text-sm">
            {error}
          </div>
        )}

        <BookForm
          onSubmit={editing ? (data) => handleUpdate(editing.id, data) : handleCreate}
          initialData={editing}
        />

        <BookList books={books} onEdit={setEditing} onDelete={handleDelete} />
      </div>
    </div>
  );
}
