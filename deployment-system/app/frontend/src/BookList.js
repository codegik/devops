import React from 'react';

export default function BookList({ books, onEdit, onDelete }) {
  if (!books.length) {
    return (
      <p className="text-gray-500 italic text-center py-4">
        No books available.
      </p>
    );
  }

  return (
    <ul className="divide-y divide-gray-200">
      {books.map((book) => (
        <li
          key={book.id}
          className="flex items-center justify-between px-4 py-3 bg-white hover:bg-gray-50 transition-colors"
        >
          <div>
            <p className="font-semibold text-gray-800">{book.title}</p>
            <p className="text-sm text-gray-500">
              by {book.author || 'Unknown'}
            </p>
          </div>

          <div className="flex gap-2">
            <button
              onClick={() => onEdit(book)}
              className="px-3 py-1 rounded-md bg-blue-600 text-white text-sm hover:bg-blue-700 transition"
              aria-label={`Edit ${book.title}`}
            >
              Edit
            </button>
            <button
              onClick={() => onDelete(book.id)}
              className="px-3 py-1 rounded-md bg-red-600 text-white text-sm hover:bg-red-700 transition"
              aria-label={`Delete ${book.title}`}
            >
              Delete
            </button>
          </div>
        </li>
      ))}
    </ul>
  );
}
