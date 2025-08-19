// src/App.test.js
import '@testing-library/jest-dom';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { booksApi } from './api/books';
import App from './App';

// IMPORTANT: mock the books API module
jest.mock('./api/books', () => ({
  booksApi: {
    list: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    remove: jest.fn(),
  },
}));


beforeEach(() => {
  jest.clearAllMocks();
});

describe('Books CRUD using booksApi mock', () => {
  it('loads empty list on start', async () => {
    // first load
    booksApi.list.mockResolvedValueOnce([]);

    render(<App />);

    // wait for initial call to happen
    await waitFor(() => expect(booksApi.list).toHaveBeenCalledTimes(1));

    // page title
    expect(screen.getByRole('heading', { name: /book manager/i })).toBeInTheDocument();
  });

  it('creates a book', async () => {
    // initial GET -> []
    booksApi.list.mockResolvedValueOnce([]);

    render(<App />);

    // POST /books
    booksApi.create.mockResolvedValueOnce({ id: 1, title: 'Test', author: 'Author' });
    // follow-up GET -> now has the created book
    booksApi.list.mockResolvedValueOnce([{ id: 1, title: 'Test', author: 'Author' }]);

    fireEvent.change(screen.getByPlaceholderText(/title/i), { target: { value: 'Test' } });
    fireEvent.change(screen.getByPlaceholderText(/author/i), { target: { value: 'Author' } });
    fireEvent.click(screen.getByRole('button', { name: /create/i }));

    // appears on screen
    await screen.findByText(/Test/);
    expect(screen.getByText(/by Author/i)).toBeInTheDocument();

    expect(booksApi.create).toHaveBeenCalledWith({ title: 'Test', author: 'Author' });
    // list called again after create
    expect(booksApi.list).toHaveBeenCalledTimes(2);
  });

  it('updates a book', async () => {
    // initial GET -> one book
    booksApi.list.mockResolvedValueOnce([{ id: 1, title: 'Test', author: 'Author' }]);

    render(<App />);

    // PUT /books/1
    booksApi.update.mockResolvedValueOnce({ id: 1, title: 'Updated', author: 'Author' });
    // follow-up GET -> updated list
    booksApi.list.mockResolvedValueOnce([{ id: 1, title: 'Updated', author: 'Author' }]);

    fireEvent.click(await screen.findByText(/edit/i));
    fireEvent.change(screen.getByPlaceholderText(/title/i), { target: { value: 'Updated' } });
    fireEvent.click(screen.getByRole('button', { name: /update/i }));

    await screen.findByText(/Updated/);
    expect(screen.getByText(/by Author/i)).toBeInTheDocument();

    expect(booksApi.update).toHaveBeenCalledWith(1, { title: 'Updated', author: 'Author' });
  });

  it('deletes a book', async () => {
    // initial GET -> one book
    booksApi.list.mockResolvedValueOnce([{ id: 1, title: 'ToRemove', author: 'A' }]);

    render(<App />);

    // DELETE /books/1
    booksApi.remove.mockResolvedValueOnce(null);
    // follow-up GET -> empty
    booksApi.list.mockResolvedValueOnce([]);

    fireEvent.click(await screen.findByRole('button', { name: /Delete/i }));

    await waitFor(() => {
      expect(screen.queryByText(/ToRemove/i)).not.toBeInTheDocument();
      expect(screen.queryByText(/by A/i)).not.toBeInTheDocument();
    });

    expect(booksApi.remove).toHaveBeenCalledWith(1);
  });
});
